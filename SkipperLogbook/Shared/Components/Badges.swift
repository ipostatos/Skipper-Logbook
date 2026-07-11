import SwiftUI

/// The `BETA` pill shown next to the wordmark. Small, quiet, unmistakable.
struct BetaBadge: View {
    @Environment(\.appTheme) private var theme
    var body: some View {
        Text("BETA")
            .font(.system(size: 10, weight: .bold))
            .tracking(1)
            .foregroundStyle(theme.background)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(theme.accent)
            )
            .accessibilityLabel(Text("badge.beta_a11y"))
    }
}

/// The "Coming soon" tag overlaid on not-yet-available features by `.comingSoon()`.
struct ComingSoonBadge: View {
    @Environment(\.appTheme) private var theme
    var body: some View {
        Text("comingsoon.badge")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(theme.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(theme.surfaceElevated)
                    .overlay(Capsule().strokeBorder(theme.hairline, lineWidth: 0.5))
            )
            .padding(8)
    }
}

#Preview("Badges") {
    HStack(spacing: 12) {
        BetaBadge()
        ComingSoonBadge()
    }
    .padding()
    .environment(\.appTheme, .paper)
}
