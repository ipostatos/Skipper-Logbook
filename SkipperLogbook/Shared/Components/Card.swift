import SwiftUI

/// The base surface used everywhere: a rounded panel with a hairline border on
/// dark themes and a soft shadow on light ones. Named `Card` (not `GlassCard`)
/// to reflect the mono ink-on-paper direction.
struct Card<Content: View>: View {
    @Environment(\.appTheme) private var theme

    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        let radius = cornerRadius ?? theme.cornerRadius
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(theme.surface)
            )
            .overlay(
                // On light the shadow carries the depth, so the border is a
                // whisper; on dark a hairline separates surfaces.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(theme.hairline, lineWidth: theme.isDark ? 1 : 0)
            )
            .cardShadow(theme)
    }
}

#Preview("Card") {
    ZStack {
        AppTheme.light.background.ignoresSafeArea()
        Card {
            Text("Sea Breeze")
                .font(AppFont.title)
                .foregroundStyle(AppTheme.light.ink)
        }
        .padding()
    }
    .environment(\.appTheme, .light)
}
