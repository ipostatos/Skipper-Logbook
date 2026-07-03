import SwiftUI

/// Typographic scale for "Liquid Nautical" — Apple-native SF Pro for text and
/// headings (bold, not huge), SF Pro Rounded tabular numerals for instruments,
/// monospaced digits for coordinates. All sizes honour Dynamic Type.
enum AppFont {

    // MARK: Display — screen titles ("Today", "Logbook") — bold SF Pro, no serif
    static func display(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold)
    }
    static var displayLarge: Font { display(40) }

    // MARK: Instruments — big numerals (heading, speed) use rounded, tabular
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static var headingNumeral: Font { numeral(56) }   // 196° hero course numeral
    static var gaugeNumeral: Font { numeral(30) }     // 2.5 kn
    static var statNumeral: Font { numeral(22) }      // grid values

    // MARK: Text
    static var title: Font { .system(.title3, design: .default).weight(.semibold) }
    static var headline: Font { .system(.headline) }
    static var body: Font { .system(.body) }
    static var callout: Font { .system(.callout) }
    static var subheadline: Font { .system(.subheadline) }
    static var footnote: Font { .system(.footnote) }
    static var caption: Font { .system(.caption) }
    static var caption2: Font { .system(.caption2) }

    /// Small ALL-CAPS labels used above values ("CURRENT SPEED", "TO WAYPOINT").
    static var label: Font {
        .system(.caption, design: .default).weight(.semibold)
    }

    /// Monospaced digits for coordinates, timers, hours.
    static func mono(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .monospaced)
    }
}

extension View {
    /// Applies an uppercased, tracked caption style used above instrument values
    /// ("CURRENT SPEED", "TO WAYPOINT"). Named to avoid clashing with the
    /// built-in `View.labelStyle(_:)`.
    func instrumentLabel(_ color: Color) -> some View {
        self.font(AppFont.label)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
