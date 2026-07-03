import SwiftUI
import Observation

/// Owns the user's chosen appearance and resolves it against the current
/// system color scheme into a concrete `AppTheme`. Persisted in `UserDefaults`.
@Observable
final class ThemeManager {

    private let defaultsKey = "settings.themeMode"

    var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: defaultsKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: defaultsKey)
        self.mode = raw.flatMap(ThemeMode.init) ?? .system
    }

    /// Resolve tokens for the effective scheme. Pass the environment
    /// `colorScheme` so `.system` follows the device; explicit modes override it.
    func theme(for systemScheme: ColorScheme) -> AppTheme {
        switch mode {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return .resolved(for: systemScheme)
        }
    }

    func select(_ mode: ThemeMode) { self.mode = mode }
}
