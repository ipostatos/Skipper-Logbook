import Foundation
import SwiftData
import CoreLocation
import Observation

/// Drives an active voyage: starts/stops recording, ingests location fixes into
/// `TrackPoint`s, integrates distance, tracks engine time, and derives the live
/// readouts the dashboard shows (speed, avg, ETA, remaining).
@Observable
@MainActor
final class VoyageRecorder {

    private(set) var activeVoyage: Voyage?
    private let context: ModelContext

    /// Current propulsion mode, toggled by the quick actions (engine/sail state).
    var propulsion: PropulsionMode = .idle
    private var engineOn = false
    private var lastEngineToggle: Date?

    init(context: ModelContext) {
        self.context = context
        self.activeVoyage = Self.fetchRecording(in: context)
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
        addEvent(.startLogging)
        addEvent(.startTrack)
        save()
        return voyage
    }

    func stopVoyage() {
        guard let voyage = activeVoyage else { return }
        if engineOn { toggleEngine() }   // close engine timer
        voyage.isRecording = false
        voyage.endedAt = .now
        activeVoyage = nil
        save()
    }

    // MARK: Ingest

    /// Feed a new fix. Appends a track point and integrates distance.
    func ingest(_ location: CLLocation) {
        guard let voyage = activeVoyage, voyage.isRecording else { return }
        let coord = GeoCoordinate(location.coordinate)
        guard coord.isValid else { return }

        if let last = voyage.orderedTrack.last {
            let delta = NavigationMath.haversineMeters(last.coordinate, coord)
            // Reject GPS jitter (< 2 m) and teleport spikes (> 1 km between fixes).
            if delta >= 2, delta < 1_000 {
                voyage.distanceMeters += delta
            }
        }

        let point = TrackPoint(timestamp: location.timestamp,
                               latitude: coord.latitude, longitude: coord.longitude,
                               speedMps: max(0, location.speed),
                               courseDegrees: location.course >= 0 ? location.course : -1,
                               propulsion: currentPropulsion)
        point.voyage = voyage
        context.insert(point)

        accrueEngineTime()
        save()
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
        do { try context.save() }
        catch { /* transient; next save retries */ }
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
