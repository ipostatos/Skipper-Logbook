import SwiftUI

/// The full-width primary action ("Start recording", "Stop recording"). Can be
/// tinted danger (stop) or accent (go).
struct PrimaryButton: View {
    @Environment(\.appTheme) private var theme

    let title: LocalizedStringKey
    var symbol: String? = nil
    var role: Role = .accent
    let action: () -> Void

    enum Role { case accent, danger, neutral }

    private var fill: Color {
        switch role {
        case .accent:  return theme.accent
        case .danger:  return theme.danger
        case .neutral: return theme.surfaceElevated
        }
    }
    private var fg: Color {
        role == .neutral ? theme.ink : theme.background
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let symbol { Image(systemName: symbol) }
                Text(title).font(.system(.headline, design: .rounded))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous)
                    .fill(fill)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A small quick-action tile (Event / Engine / Sails / MOB) used in the
/// dashboard's Quick Actions row and the + sheet.
struct QuickActionButton: View {
    @Environment(\.appTheme) private var theme

    let symbol: String
    let title: LocalizedStringKey
    var isDanger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isDanger ? theme.danger : theme.accent)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.inkSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous)
                            .strokeBorder(isDanger ? theme.danger.opacity(0.4) : theme.hairline,
                                          lineWidth: theme.isDark ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Stop recording", symbol: "stop.fill", role: .danger) {}
        HStack {
            QuickActionButton(symbol: "note.text", title: "Event") {}
            QuickActionButton(symbol: "fanblades.fill", title: "Engine ON") {}
            QuickActionButton(symbol: "exclamationmark.triangle.fill", title: "MOB", isDanger: true) {}
        }
    }
    .padding()
    .environment(\.appTheme, .paper)
}
