import Foundation
import SwiftData
import CoreLocation
import Observation
import os

/// Drives an active voyage: starts/stops recording, ingests location fixes into
/// `TrackPoint`s, integrates distance, tracks engine time, and derives the live
/// readouts the dashboard shows (speed, avg, ETA, remaining).
@Observable
@MainActor
final class VoyageRecorder {

    private(set) var activeVoyage: Voyage?
    private let context: ModelContext
    private let log = Logger(subsystem: "com.skipperlogbook.app", category: "VoyageRecorder")

    /// Current propulsion mode, toggled by the quick actions (engine/sail state).
    var propulsion: PropulsionMode = .idle
    /// Single source of truth for the engine chip — views read this, never a
    /// parallel flag (a duplicated flag once desynced engine hours from the UI).
    private(set) var engineOn = false
    private var lastEngineToggle: Date?

    /// Fired on voyage meta changes (start / stop / destination) so the widget
    /// coordinator can rebuild the snapshot immediately, bypassing its throttle.
    var onVoyageMetaChange: (() -> Void)?

    /// Last ingested position — kept here so the hot path never touches
    /// `orderedTrack` (which sorts the whole relationship array on every call).
    private var lastPointCoord: GeoCoordinate?

    /// Track points are batched to disk: a save every fix (~every 5 m) is pure
    /// write amplification. Logbook events still save immediately — they are
    /// rare and precious.
    private var pendingPoints = 0
    private var lastTrackSaveAt = Date.distantPast
    private let saveEveryPoints = 10
    private let saveEverySeconds: TimeInterval = 12

    init(context: ModelContext) {
        self.context = context
        self.activeVoyage = Self.fetchRecording(in: context)
        if let voyage = activeVoyage {
            // One-time sort at launch is fine; per-fix sorts are not.
            lastPointCoord = voyage.orderedTrack.last?.coordinate
            restoreEngineState(from: voyage)
        }
    }

    /// After a process restart mid-voyage the in-memory engine flag is lost
    /// while the logbook still says "engine on" — without this, engine hours
    /// stop accruing and the next toggle writes a second `engineOn`. We resume
    /// counting from relaunch (the dark interval is not invented).
    private func restoreEngineState(from voyage: Voyage) {
        let lastEngineEvent = voyage.chronologicalEvents.last {
            $0.type == .engineOn || $0.type == .engineOff
        }
        if lastEngineEvent?.type == .engineOn {
            engineOn = true
            lastEngineToggle = .now
            if propulsion == .idle { propulsion = .engine }
        }
    }

    var isRecording: Bool { activeVoyage?.isRecording ?? false }

    // MARK: Lifecycle

    @discardableResult
    func startVoyage(named name: String, destination: GeoCoordinate? = nil,
                     destinationName: String? = nil) -> Voyage {
        // Close any stale recording first.
        if let current = activeVoyage, current.isRecording { stopVoyage() }

        let voyage = Voyage(name: name, startedAt: .now, isRecording: true,
                            destinationName: destinationName,
                            destinationLat: destination?.latitude,
                            destinationLon: destination?.longitude)
        context.insert(voyage)
        activeVoyage = voyage
        lastPointCoord = nil
        pendingPoints = 0
        addEvent(.startLogging)
        addEvent(.startTrack)
        save()
        onVoyageMetaChange?()
        return voyage
    }

    func stopVoyage() {
        guard let voyage = activeVoyage else { return }
        if engineOn { toggleEngine() }   // close engine timer
        voyage.isRecording = false
        voyage.endedAt = .now
        activeVoyage = nil
        lastPointCoord = nil
        pendingPoints = 0
        save()                            // flushes any batched track points too
        onVoyageMetaChange?()
    }

    // MARK: Ingest

    /// Feed a new fix. Appends a track point and integrates distance.
    func ingest(_ location: CLLocation) {
        guard let voyage = activeVoyage, voyage.isRecording else { return }
        let coord = GeoCoordinate(location.coordinate)
        guard coord.isValid else { return }
        // Garbage fixes never reach the track; only confident ones (≤ 50 m)
        // feed the integrated distance — a 100 m-accuracy fix can "add" a
        // hundred phantom metres while moored.
        let accuracy = location.horizontalAccuracy
        guard accuracy > 0, accuracy <= 100 else { return }

        if let last = lastPointCoord {
            let delta = NavigationMath.haversineMeters(last, coord)
            // Reject GPS jitter (< 2 m) and teleport spikes (> 1 km between fixes).
            if accuracy <= 50, delta >= 2, delta < 1_000 {
                voyage.distanceMeters += delta
            }
        }
        lastPointCoord = coord

        let point = TrackPoint(timestamp: location.timestamp,
                               latitude: coord.latitude, longitude: coord.longitude,
                               speedMps: max(0, location.speed),
                               courseDegrees: location.course >= 0 ? location.course : -1,
                               propulsion: currentPropulsion)
        point.voyage = voyage
        context.insert(point)

        accrueEngineTime()
        pendingPoints += 1
        if pendingPoints >= saveEveryPoints
            || Date.now.timeIntervalSince(lastTrackSaveAt) >= saveEverySeconds {
            pendingPoints = 0
            lastTrackSaveAt = .now
            save()
        }
    }

    // MARK: Quick actions / events

    func toggleEngine() {
        engineOn.toggle()
        if engineOn {
            lastEngineToggle = .now
            addEvent(.engineOn)
        } else {
            accrueEngineTime()
            lastEngineToggle = nil
            addEvent(.engineOff)
        }
    }

    /// The one engine toggle every screen calls (Today, Quick Actions).
    /// Outside a recording only the flag flips (chips + starting propulsion);
    /// during one, hours accrue and the event is logged. `sailsUp` is the
    /// current sail-chip state, so propulsion stays consistent no matter which
    /// screen toggled the engine.
    func toggleEngine(sailsUp: Bool) {
        if isRecording {
            toggleEngine()
        } else {
            engineOn.toggle()
        }
        propulsion = engineOn ? (sailsUp ? .sailsAndEngine : .engine)
                              : (sailsUp ? .sails : .idle)
    }

    /// Keeps propulsion in agreement after the sail chips change.
    func setSailState(up: Bool) {
        propulsion = up ? (engineOn ? .sailsAndEngine : .sails)
                        : (engineOn ? .engine : .idle)
    }

    private func accrueEngineTime() {
        guard engineOn, let since = lastEngineToggle, let voyage = activeVoyage else { return }
        let now = Date.now
        voyage.engineSeconds += now.timeIntervalSince(since)
        lastEngineToggle = now
    }

    private var currentPropulsion: PropulsionMode {
        switch (engineOn, propulsion) {
        case (true, .sails), (true, .sailsAndEngine): return .sailsAndEngine
        case (true, _): return .engine
        case (false, .sails): return .sails
        default: return propulsion
        }
    }

    @discardableResult
    func addEvent(_ type: LogEventType,
                  at coordinate: GeoCoordinate? = nil,
                  heading: Double? = nil,
                  speedKn: Double? = nil,
                  note: String? = nil,
                  windDirection: String? = nil,
                  windSpeedKn: Double? = nil,
                  mainsailPercent: Int? = nil,
                  jibPercent: Int? = nil) -> LogEvent {
        let voyage = activeVoyage
        let event = LogEvent(type: type,
                             latitude: coordinate?.latitude,
                             longitude: coordinate?.longitude,
                             headingDegrees: heading,
                             speedKnots: speedKn,
                             legDistanceNM: voyage?.distanceNM,
                             note: note,
                             windDirection: windDirection,
                             windSpeedKn: windSpeedKn,
                             mainsailPercent: mainsailPercent,
                             jibPercent: jibPercent)
        event.voyage = voyage
        context.insert(event)
        save()
        return event
    }

    /// Sets or moves the active voyage's destination waypoint, logs the turn,
    /// and persists — the one place the waypoint rules live, whatever screen
    /// sets it.
    func setDestination(_ coordinate: GeoCoordinate, name: String? = nil,
                        from current: GeoCoordinate? = nil, heading: Double? = nil) {
        guard let voyage = activeVoyage else { return }
        voyage.destinationLat = coordinate.latitude
        voyage.destinationLon = coordinate.longitude
        if let name {
            voyage.destinationName = name
        } else if voyage.destinationName == nil {
            voyage.destinationName = String(localized: "map.waypoint")
        }
        addEvent(.turnToWaypoint, at: current, heading: heading) // also saves
        onVoyageMetaChange?()
    }

    // MARK: Derived live values

    func remainingDistanceMeters(from coordinate: GeoCoordinate?) -> Double? {
        guard let dest = activeVoyage?.destination, let here = coordinate else { return nil }
        return NavigationMath.haversineMeters(here, dest)
    }

    func etaSeconds(from coordinate: GeoCoordinate?, speedMps: Double) -> Double? {
        guard let remaining = remainingDistanceMeters(from: coordinate) else { return nil }
        return NavigationMath.etaSeconds(distanceMeters: remaining, speedMps: speedMps)
    }

    func bearingToDestination(from coordinate: GeoCoordinate?) -> Double? {
        guard let dest = activeVoyage?.destination, let here = coordinate else { return nil }
        return NavigationMath.initialBearingDegrees(from: here, to: dest)
    }

    // MARK: Persistence

    private func save() {
        // Transient failures retry on the next fix, but never silently.
        do {
            try context.save()
        } catch {
            log.error("Recorder save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func fetchRecording(in context: ModelContext) -> Voyage? {
        var descriptor = FetchDescriptor<Voyage>(
            predicate: #Predicate { $0.isRecording == true },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
