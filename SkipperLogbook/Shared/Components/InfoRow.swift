import SwiftUI

/// A key/value row used in spec tables (Vessel details) and tappable list rows
/// (Position, ETA). Optional leading symbol and trailing chevron.
struct InfoRow: View {
    @Environment(\.appTheme) private var theme

    var symbol: String?
    let label: LocalizedStringKey
    let value: String
    var showsChevron: Bool = false
    var monospacedValue: Bool = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.accent)
                    .frame(width: 24)
            }
            Text(label)
                .font(AppFont.subheadline)
                .foregroundStyle(theme.inkSecondary)
            Spacer(minLength: Spacing.md)
            Text(value)
                .font(monospacedValue ? AppFont.mono(.subheadline) : AppFont.subheadline)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.trailing)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.inkTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// A titled section label (serif, small caps optional) with an optional accessory.
struct SectionHeader<Accessory: View>: View {
    @Environment(\.appTheme) private var theme
    let title: LocalizedStringKey
    @ViewBuilder var accessory: () -> Accessory

    init(_ title: LocalizedStringKey, @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }) {
        self.title = title
        self.accessory = accessory
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(theme.ink)
            Spacer()
            accessory()
        }
    }
}
