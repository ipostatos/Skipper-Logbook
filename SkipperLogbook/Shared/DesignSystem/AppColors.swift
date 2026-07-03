import SwiftUI

/// Convenience accessors that pull semantic colors from the environment theme.
/// Prefer `@Environment(\.appTheme)` directly in views; this exists for the few
/// call sites that want a color without capturing the whole theme.
struct AppColors {
    let theme: AppTheme

    var background: Color { theme.background }
    var surface: Color { theme.surface }
    var ink: Color { theme.ink }
    var inkSecondary: Color { theme.inkSecondary }
    var accent: Color { theme.accent }
    var danger: Color { theme.danger }
    var success: Color { theme.success }
    var sail: Color { theme.sail }
}

extension EnvironmentValues {
    var appColors: AppColors { AppColors(theme: appTheme) }
}
