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

    // MARK: Snapshot for widgets

    /// Push the latest state to the App Group and ask WidgetKit to reload.
    func publish(_ snapshot: VoyageSnapshot) {
        var s = snapshot
        s.updatedEpoch = Date.now.timeIntervalSince1970
        SharedStore.write(s)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Live Activity lifecycle

    func startActivity(name: String, origin: String?, destination: String?,
                       state: VoyageActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if activity != nil { Task { await update(state) }; return }
        let attributes = VoyageActivityAttributes(voyageName: name, origin: origin, destination: destination)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Activities may be disabled; fail silently.
        }
    }

    func update(_ state: VoyageActivityAttributes.ContentState) async {
        guard let activity else { return }
        await activity.update(.init(state: state, staleDate: nil))
    }

    func endActivity() async {
        guard let activity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        self.activity = nil
    }
}
