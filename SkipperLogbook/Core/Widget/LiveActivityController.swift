import Foundation
import ActivityKit
import WidgetKit
import Observation

/// Bridges the running app to widgets and the Live Activity: it writes the
/// shared `VoyageSnapshot` (so home-screen / lock-screen widgets refresh) and
/// starts / updates / ends the active-voyage Live Activity.
@Observable
@MainActor
final class LiveActivityController {

    private var activity: Activity<VoyageActivityAttributes>?

    /// Every update carries a stale date: if the app stops feeding the activity
    /// (GPS dropout, force-quit, crash), the system marks it stale and the
    /// widget UI can stop presenting a frozen speed as live data.
    private var staleDate: Date { Date.now.addingTimeInterval(180) }

    // MARK: Snapshot for widgets

    /// Push the latest state to the App Group and ask WidgetKit to reload.
    /// NOTE: WidgetKit budgets timeline reloads (a few dozen per day) — callers
    /// must throttle this (see `FixCoordinator`); per-fix Live Activity updates
    /// go through `startActivity`/`update` instead, which are not budgeted.
    func publish(_ snapshot: VoyageSnapshot) {
        var s = snapshot
        s.updatedEpoch = Date.now.timeIntervalSince1970
        SharedStore.write(s)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Live Activity lifecycle

    /// Re-attach to an activity that survived a force-quit or reboot. Without
    /// this the old activity sits orphaned on the Lock Screen (the in-memory
    /// handle is gone) and the next voyage start would create a duplicate.
    /// Returns whether an activity is attached and alive afterwards.
    @discardableResult
    func adoptOrphans(recording: Bool) -> Bool {
        let existing = Activity<VoyageActivityAttributes>.activities
        guard !existing.isEmpty else { return false }
        if recording, let keep = existing.first {
            activity = keep
            for extra in existing.dropFirst() {
                Task { await extra.end(nil, dismissalPolicy: .immediate) }
            }
            return true
        }
        for orphan in existing {
            Task { await orphan.end(nil, dismissalPolicy: .immediate) }
        }
        return false
    }

    func startActivity(name: String, origin: String?, destination: String?,
                       state: VoyageActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if activity != nil { Task { await update(state) }; return }
        let attributes = VoyageActivityAttributes(voyageName: name, origin: origin, destination: destination)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: staleDate),
                pushType: nil
            )
        } catch {
            // Activities may be disabled; fail silently.
        }
    }

    func update(_ state: VoyageActivityAttributes.ContentState) async {
        guard let activity else { return }
        await activity.update(.init(state: state, staleDate: staleDate))
    }

    /// Ends the tracked activity AND any stray ones of our type — after process
    /// restarts the in-memory handle can be nil while an activity still lives.
    func endActivity() async {
        for stray in Activity<VoyageActivityAttributes>.activities {
            await stray.end(nil, dismissalPolicy: .immediate)
        }
        if let activity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        activity = nil
    }
}
