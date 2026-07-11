import SwiftUI

/// Appearance selection. "Liquid Nautical" is a light-first language (Apple
/// Health / Maps feel). Dark is a neutral system-style dark, not a navy cockpit.
enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .light:  return "theme.light"
        case .dark:   return "theme.dark"
        case .system: return "theme.system"
        }
    }

    var symbol: String {
        switch self {
        case .light:  return "sun.max"
        case .dark:   return "moon.stars"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }
}

/// A per-screen accent role. Each primary screen leans on ONE strong accent so
/// the app stays calm; MOB/emergency is always the reserved red.
enum AccentRole {
    case blue      // Today / navigation
    case cyan      // Map / track
    case purple    // Log / route
    case green     // Vessel / sails / OK
    case orange    // Engine / maintenance
    case red       // MOB / danger (reserved)
}

/// Resolved color + shape tokens for one appearance. The "Liquid Nautical"
/// palette: bright surfaces, calm maritime accents, a single reserved red.
struct AppTheme: Equatable {

    // Surfaces
    let background: Color
    let surface: Color            // glass card fill
    let surfaceElevated: Color    // sheets, floating bars
    let hairline: Color

    // Text
    let ink: Color
    let inkSecondary: Color
    let inkTertiary: Color

    // Semantic accents (the maritime palette)
    let blue: Color
    let cyan: Color
    let purple: Color
    let green: Color
    let orange: Color
    let warning: Color
    let danger: Color             // MOB red — reserved

    // Map tints (Apple-Maps-like nautical light)
    let mapWater: Color
    let mapLand: Color

    // Shape
    let cornerRadius: CGFloat
    let cornerRadiusSmall: CGFloat

    var isDark: Bool

    // MARK: Accent resolution

    /// The strong accent for a screen's role.
    func accent(_ role: AccentRole) -> Color {
        switch role {
        case .blue:   return blue
        case .cyan:   return cyan
        case .purple: return purple
        case .green:  return green
        case .orange: return orange
        case .red:    return danger
        }
    }

    /// A soft tinted fill behind an accent (12% on light, 22% on dark).
    func accentSoft(_ role: AccentRole) -> Color {
        accent(role).opacity(isDark ? 0.22 : 0.12)
    }

    /// Default app accent (used by `.tint` and generic controls).
    var accent: Color { blue }
    /// Generic soft fill for the default accent.
    var accentSoft: Color { blue.opacity(isDark ? 0.22 : 0.12) }
    /// Sails / green-tinted things.
    var sail: Color { green }
    /// "OK"/success semantic — green in this palette.
    var success: Color { green }

    // MARK: Variants

    /// Light — bright, milky background with white glass cards.
    static let light = AppTheme(
        background: Color(hex: "F7F8FB"),
        surface: Color(hex: "FFFFFF"),
        surfaceElevated: Color(hex: "FFFFFF"),
        hairline: Color(hex: "ECEEF3"),
        ink: Color(hex: "111827"),
        inkSecondary: Color(hex: "8A93A5"),
        inkTertiary: Color(hex: "B7BECC"),
        blue: Color(hex: "3B6CFF"),
        cyan: Color(hex: "28C7D8"),
        purple: Color(hex: "6E6AF8"),
        green: Color(hex: "39D98A"),
        orange: Color(hex: "FFB340"),
        warning: Color(hex: "FFCC4D"),
        danger: Color(hex: "FF3B30"),
        mapWater: Color(hex: "EAF6FF"),
        mapLand: Color(hex: "F4F1EA"),
        cornerRadius: 22,
        cornerRadiusSmall: 16,
        isDark: false
    )

    /// Dark — neutral Apple-style dark (elevated grey surfaces), same accents.
    static let dark = AppTheme(
        background: Color(hex: "0C0F14"),
        surface: Color(hex: "171A21"),
        surfaceElevated: Color(hex: "1F232C"),
        hairline: Color(hex: "2A2F39"),
        ink: Color(hex: "F5F7FA"),
        inkSecondary: Color(hex: "9AA3B2"),
        inkTertiary: Color(hex: "5C6472"),
        blue: Color(hex: "5B84FF"),
        cyan: Color(hex: "3DD6E6"),
        purple: Color(hex: "8A86FF"),
        green: Color(hex: "45E39A"),
        orange: Color(hex: "FFBF57"),
        warning: Color(hex: "FFD469"),
        danger: Color(hex: "FF5A50"),
        mapWater: Color(hex: "0E2233"),
        mapLand: Color(hex: "1C1F24"),
        cornerRadius: 22,
        cornerRadiusSmall: 16,
        isDark: true
    )

    static func resolved(for scheme: ColorScheme) -> AppTheme {
        scheme == .dark ? .dark : .light
    }

    // Back-compat aliases used by earlier previews/screens.
    static var paper: AppTheme { .light }
    static var night: AppTheme { .dark }
}
