import SwiftUI

/// The More tab: a grid of colored tiles routing to the vessel binder — vessel,
/// crew, maintenance/engine log, service notes, season log, equipment, deviation,
/// safety, statistics, settings. Mirrors the colored tile menu in the mockups.
struct MoreMenuView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 2)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                tile("more.vessel", "sailboat.fill", Color(hex: "1F6E8C")) { router.morePathAppend(.vessel) }
                tile("more.engine_log", "fanblades.fill", Color(hex: "C77E3A")) { router.morePathAppend(.maintenance) }
                tile("more.service_notes", "book.closed.fill", Color(hex: "3E7C57")) { router.morePathAppend(.serviceNotes) }
                tile("more.season_log", "sun.max.fill", Color(hex: "2E86AB")) { router.morePathAppend(.seasonLog) }
                tile("more.crew", "person.2.fill", Color(hex: "6A2C91")) { router.morePathAppend(.crew) }
                tile("more.equipment", "shippingbox.fill", Color(hex: "8A1C4B")) { router.morePathAppend(.equipment) }
                tile("more.deviation", "location.north.circle.fill", Color(hex: "9A7B12")) { router.morePathAppend(.deviation) }
                tile("more.weather", "cloud.sun.fill", Color(hex: "2C7DA0")) { router.morePathAppend(.weather) }
                tile("more.statistics", "chart.bar.fill", Color(hex: "3B5BA5")) { router.morePathAppend(.statistics) }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("tab.more")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.morePathAppend(.settings) } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private func tile(_ title: LocalizedStringKey, _ symbol: String, _ color: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(2)
                Spacer(minLength: Spacing.lg)
                HStack {
                    Spacer()
                    Image(systemName: symbol)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(Spacing.md)
            .frame(height: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(color.gradient)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("More") {
    NavigationStack {
        MoreMenuView()
            .environment(\.appTheme, .paper)
            .environment(AppRouter())
    }
}
