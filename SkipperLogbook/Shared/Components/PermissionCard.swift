import SwiftUI

/// Explains a missing system permission and offers the one action that fixes
/// it. Shown wherever a denied permission degrades a feature (e.g. Today when
/// location access is denied) — the app keeps working, this just says why the
/// live numbers are missing and where to turn them back on.
struct PermissionCard: View {
    @Environment(\.appTheme) private var theme

    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(theme.accentSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(AppFont.headline).foregroundStyle(theme.ink)
                        Text(message).font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    }
                    Spacer(minLength: 0)
                }
                PrimaryButton(title: actionTitle, symbol: "gear", role: .accent, action: action)
            }
        }
    }
}

#Preview("Permission card") {
    ZStack {
        AppTheme.light.background.ignoresSafeArea()
        PermissionCard(symbol: "location.slash",
                       title: "permission.location_card_title",
                       message: "permission.location_card_message",
                       actionTitle: "permission.open_settings") {}
            .padding()
    }
    .environment(\.appTheme, .light)
}
