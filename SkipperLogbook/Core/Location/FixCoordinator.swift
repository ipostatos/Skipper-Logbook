import Foundation
import CoreLocation
import SwiftData

/// Routes every accepted GPS fix to the engines (voyage recorder, anchor watch,
/// MOB) and keeps widgets + the Live Activity in sync — from OUTSIDE the view
/// layer. Previously this fan-out lived in `RootView.onChange`, which meant the
/// anchor alarm depended on a SwiftUI scene being alive and updating; an alarm
/// that dies with the UI is decoration. As long as the process runs and
/// CoreLocation delivers fixes, this coordinator runs.
///
/// It is also the budget gatekeeper for WidgetKit: the Live Activity is updated
/// on every fix (local updates are effectively unthrottled), but the App-Group
/// snapshot + `reloadAllTimelines()` — which iOS budgets to a few dozen reloads
/// a day — happen only on voyage events and on a coarse timer.
@MainActor
final class FixCoordinator {

    private let location: LocationManager
    private let recorder: VoyageRecorder
    private let anchorWatch: AnchorWatchEngine
    private let mob: MOBEngine
    private let liveActivity: LiveActivityController
    private let context: ModelContext

    /// Snapshot/timeline reloads on plain fixes happen at most this often.
    /// Voyage events (start/stop/waypoint) bypass the throttle via
    /// `syncWidgetsNow()`.
    private let snapshotInterval: TimeInterval = 600
    private var lastSnapshotAt = Date.distantPast
    /// Tracks whether we currently own a Live Activity, so ending it happens
    /// once on the recording→idle transition instead of spawning a Task per fix.
    private var activityRunning = false

    init(location: LocationManager,
         recorder: VoyageRecorder,
         anchorWatch: AnchorWatchEngine,
         mob: MOBEngine,
         liveActivity: LiveActivityController,
         context: ModelContext) {
        self.location = location
        self.recorder = recorder
        self.anchorWatch = anchorWatch
        self.mob = mob
        self.liveActivity = liveActivity
        self.context = context
    }

    /// Wire up and do the initial sync. Call once from the app's init.
    func activate() {
        location.onFix = { [weak self] fix in self?.handle(fix) }
        recorder.onVoyageMetaChange = { [weak self] in self?.syncWidgetsNow() }
        // Re-attach or close a Live Activity that survived a force-quit/reboot —
        // otherwise it sits orphaned on the Lock Screen and a new start would
        // create a duplicate.
        activityRunning = liveActivity.adoptOrphans(recording: recorder.isRecording)
        syncWidgetsNow()
    }

    // MARK: Per-fix path (cheap)

    private func handle(_ fix: CLLocation) {
        recorder.ingest(fix)
        let geo = GeoCoordinate(fix.coordinate)
        anchorWatch.ingest(geo)
        mob.ingest(boat: geo)

        // Belt and braces for background updates: the UI normally sets the
        // safety override when a watch starts, but enforce it here too so the
        // setting never depends on a live scene.
        let needsBackground = anchorWatch.isActive || mob.isActive
        if location.safetyBackgroundOverride != needsBackground {
            location.safetyBackgroundOverride = needsBackground
        }

        driveLiveActivity()

        if Date.now.timeIntervalSince(lastSnapshotAt) >= snapshotInterval {
            syncWidgetsNow()
        }
    }

    /// Live Activity state built from in-memory values only — no fetches.
    private func driveLiveActivity() {
        guard recorder.isRecording, let voyage = recorder.activeVoyage else {
            if activityRunning {
                activityRunning = false
                Task { await liveActivity.endActivity() }
            }
            return
        }
        let coord = location.currentCoordinate
        let remainingM = recorder.remainingDistanceMeters(from: coord)
        let state = VoyageActivityAttributes.ContentState(
            speedKn: Units.mpsToKnots(location.speedMps),
            courseDegrees: location.effectiveHeading,
            distanceNM: voyage.distanceNM,
            remainingNM: remainingM.map(Units.metersToNM),
            etaEpoch: recorder.etaSeconds(from: coord, speedMps: location.speedMps)
                .map { Date.now.addingTimeInterval($0).timeIntervalSince1970 },
            progress: routeProgress(voyage: voyage, remainingM: remainingM),
            isRecording: true)
        liveActivity.startActivity(name: voyage.name, origin: nil,
                                   destination: voyage.destinationName, state: state)
        activityRunning = true
    }

    // MARK: Event path (full snapshot, throttle bypassed)

    /// Rebuilds the widget snapshot (the expensive part: store fetches) and asks
    /// WidgetKit to reload. Called on voyage start/stop/waypoint changes and at
    /// most every `snapshotInterval` from the fix path.
    func syncWidgetsNow() {
        lastSnapshotAt = .now
        let coord = location.currentCoordinate
        let voyage = recorder.activeVoyage
        let vessel = (try? context.fetch(FetchDescriptor<Vessel>()))?.first
        let allVoyages = (try? context.fetch(FetchDescriptor<Voyage>())) ?? []
        let remainingM = recorder.remainingDistanceMeters(from: coord)

        // This-month streak
        let cal = Calendar.current
        let monthVoyages = allVoyages.filter { cal.isDate($0.startedAt, equalTo: .now, toGranularity: .month) }
        let milesThisMonth = monthVoyages.reduce(0) { $0 + $1.distanceNM }

        // Soonest maintenance
        let maint = (try? context.fetch(FetchDescriptor<MaintenanceItem>())) ?? []
        let nextService = maint.compactMap { item -> (String, Double)? in
            guard let hours = item.nextServiceHours, let done = item.engineHoursAtService else { return nil }
            return (item.title, max(0, hours - done))
        }.min { $0.1 < $1.1 }

        let snapshot = VoyageSnapshot(
            isRecording: recorder.isRecording,
            voyageName: voyage?.name ?? "",
            origin: nil,
            destination: voyage?.destinationName,
            speedKn: Units.mpsToKnots(location.speedMps),
            courseDegrees: location.effectiveHeading,
            distanceNM: voyage?.distanceNM ?? 0,
            remainingNM: remainingM.map(Units.metersToNM),
            etaEpoch: recorder.etaSeconds(from: coord, speedMps: location.speedMps)
                .map { Date.now.addingTimeInterval($0).timeIntervalSince1970 },
            fuelPercent: fuelPercent(vessel: vessel, voyage: voyage),
            nextServiceTitle: nextService?.0,
            nextServiceHoursLeft: nextService?.1,
            voyagesThisMonth: monthVoyages.count,
            milesThisMonth: milesThisMonth,
            updatedEpoch: 0
        )
        liveActivity.publish(snapshot)
        driveLiveActivity()
    }

    // MARK: Derivations

    private func fuelPercent(vessel: Vessel?, voyage: Voyage?) -> Double? {
        guard let cap = vessel?.fuelCapacityLiters, cap > 0 else { return nil }
        let used = voyage?.fuelUsedLiters ?? 0
        return max(0, min(100, (cap - used) / cap * 100))
    }

    private func routeProgress(voyage: Voyage?, remainingM: Double?) -> Double {
        guard let planned = voyage?.plannedDistanceMeters, planned > 0,
              let remaining = remainingM else {
            // Fall back to distance-so-far vs. distance+remaining.
            let done = (voyage?.distanceMeters ?? 0)
            let rem = remainingM ?? 0
            let total = done + rem
            return total > 0 ? min(1, done / total) : 0
        }
        return min(1, max(0, 1 - remaining / planned))
    }
}
