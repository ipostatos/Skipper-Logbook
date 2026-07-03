import SwiftUI

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .paper
}

extension EnvironmentValues {
    /// The resolved color/shape tokens for the active appearance.
    /// Injected once at the app root; read everywhere via `@Environment(\.appTheme)`.
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
