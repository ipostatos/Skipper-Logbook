import SwiftUI

/// A boat-state tile: colored SF Symbol on a white glass card, a bold value and
/// a small "Tap to …" caption. Engine=orange, Sails=blue, Anchor=green, etc.
/// Matches the Liquid Nautical quick-state grid.
struct StatusChip: View {
    @Environment(\.appTheme) private var theme

    let symbol: String
    let title: LocalizedStringKey
    let value: String
    let role: AccentRole
    var isActive: Bool = true
    var caption: LocalizedStringKey? = nil

    private var color: Color { theme.accent(role) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive ? color : theme.inkTertiary)
                Spacer()
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.inkSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? color : theme.inkSecondary)
                .monospacedDigit()
            if let caption {
                Text(caption)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.inkTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous)
                .strokeBorder(theme.hairline, lineWidth: theme.isDark ? 1 : 0)
        )
        .cardShadow(theme)
        .accessibilityElement(children: .combine)
    }
}

/// The 2×2 (or 1×4) grid of boat-state tiles shown on Today.
struct StatusChipRow: View {
    let engineOn: Bool
    let mainsailPercent: Int?
    let jibPercent: Int?
    let anchorDown: Bool
    var onEngine: () -> Void = {}
    var onSails: () -> Void = {}
    var onAnchor: () -> Void = {}
    var onNote: () -> Void = {}

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            Button(action: onEngine) {
                StatusChip(symbol: engineOn ? "fanblades.fill" : "fanblades",
                           title: "status.engine",
                           value: engineOn ? String(localized: "chip.on") : String(localized: "chip.off"),
                           role: .orange, isActive: engineOn, caption: "status.tap_toggle")
            }.buttonStyle(.plain)
            Button(action: onSails) {
                StatusChip(symbol: "sailboat.fill", title: "status.sails",
                           value: mainsailPercent.map { "\($0)%" } ?? "—",
                           role: .blue, isActive: (mainsailPercent ?? 0) > 0, caption: "status.tap_log")
            }.buttonStyle(.plain)
            Button(action: onAnchor) {
                StatusChip(symbol: anchorDown ? "anchor.fill" : "anchor",
                           title: "status.anchor",
                           value: anchorDown ? String(localized: "chip.down") : String(localized: "chip.up"),
                           role: .green, isActive: anchorDown, caption: "status.tap_log")
            }.buttonStyle(.plain)
            Button(action: onNote) {
                StatusChip(symbol: "square.and.pencil", title: "status.note",
                           value: String(localized: "chip.add"),
                           role: .purple, isActive: true, caption: "status.tap_add")
            }.buttonStyle(.plain)
        }
    }
}

#Preview("Status tiles") {
    StatusChipRow(engineOn: false, mainsailPercent: 75, jibPercent: 75, anchorDown: false)
        .padding()
        .environment(\.appTheme, .light)
        .background(AppTheme.light.background)
}
