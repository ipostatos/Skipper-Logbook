import SwiftUI

/// Spacing, radius and shadow constants. One source of truth so screens stay on
/// a consistent rhythm and match the mockups' generous whitespace.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// Horizontal page inset used by every screen's scroll content.
    static let pageMargin: CGFloat = 20

    /// Height reserved at the bottom of scroll views so content clears the
    /// custom tab bar (bar height + safe-area handled by the bar itself).
    static let tabBarClearance: CGFloat = 96
}

/// A soft, low "liquid glass" card shadow. Light theme leans on the shadow for
/// depth (Apple-Health feel); dark theme uses a very subtle lift.
struct CardShadow: ViewModifier {
    let theme: AppTheme
    func body(content: Content) -> some View {
        if theme.isDark {
            content.shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        } else {
            content.shadow(color: Color(hex: "8A93A5").opacity(0.12), radius: 18, x: 0, y: 10)
        }
    }
}

extension View {
    func cardShadow(_ theme: AppTheme) -> some View {
        modifier(CardShadow(theme: theme))
    }
}
