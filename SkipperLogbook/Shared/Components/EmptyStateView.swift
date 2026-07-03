import SwiftUI

/// A centered, quiet empty state for lists with no content yet.
struct EmptyStateView: View {
    @Environment(\.appTheme) private var theme

    let symbol: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(theme.inkTertiary)
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(theme.ink)
            if let message {
                Text(message)
                    .font(AppFont.subheadline)
                    .foregroundStyle(theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview("Empty") {
    EmptyStateView(symbol: "tray", title: "No entries yet",
                   message: "Start recording a voyage to see your log fill up.")
        .padding()
        .environment(\.appTheme, .paper)
}
