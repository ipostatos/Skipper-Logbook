import SwiftUI
import Observation

/// App-wide, non-persistent-model state: onboarding completion, unit preference,
/// and the live boat-state used by the dashboard chips (engine/sails/anchor).
/// Model data lives in SwiftData; this holds ephemeral/UI state.
@Observable
@MainActor
final class AppState {

    // Onboarding
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    // Units
    var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: Keys.units) }
    }

    // Live boat state (reflected by the dashboard status chips & quick actions).
    // Anchor state lives in AnchorWatchEngine — the single source of truth.
    var engineOn = false
    var mainsailPercent: Int?
    var jibPercent: Int?

    private enum Keys {
        static let onboarding = "state.hasCompletedOnboarding"
        static let units = "settings.unitSystem"
    }

    init() {
        // Screenshot / UI-test harness: skip onboarding so the run lands on the
        // tab shell (the `--skip-onboarding` flag is dev-only, never in prod).
        let skipOnboarding = ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
        self.hasCompletedOnboarding = skipOnboarding
            || UserDefaults.standard.bool(forKey: Keys.onboarding)
        let rawUnits = UserDefaults.standard.string(forKey: Keys.units)
        self.unitSystem = rawUnits.flatMap(UnitSystem.init) ?? .nautical
    }
}
