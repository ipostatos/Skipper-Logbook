import SwiftUI
import SwiftData

/// The engine / maintenance log (Тех. журнал): completed service records with
/// engine hours, plus a next-service card. Auto-scheduling/reminders are marked
/// Coming soon.
struct MaintenanceView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \MaintenanceItem.performedAt, order: .reverse) private var items: [MaintenanceItem]

    /// The soonest upcoming service, if any target dates/hours exist.
    private var nextService: MaintenanceItem? {
        items.filter { $0.nextServiceDate != nil || $0.nextServiceHours != nil }
            .sorted { ($0.nextServiceDate ?? .distantFuture) < ($1.nextServiceDate ?? .distantFuture) }
            .first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if items.isEmpty {
                    EmptyStateView(symbol: "wrench.and.screwdriver", title: "maintenance.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                                MaintenanceItemRow(item: item)
                                if i < items.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                    if let next = nextService { NextServiceCard(item: next) }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("maintenance.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: { Image(systemName: "plus") }.comingSoon()
            }
        }
    }
}

/// A service record row: title, date, hours, detail.
struct MaintenanceItemRow: View {
    @Environment(\.appTheme) private var theme
    let item: MaintenanceItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(AppFont.subheadline.weight(.semibold)).foregroundStyle(theme.ink)
                Text(item.performedAt.shortDate).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                if let detail = item.detail {
                    Text(detail).font(AppFont.caption).foregroundStyle(theme.inkTertiary)
                }
            }
            Spacer()
            if let hours = item.engineHoursAtService {
                Text("\(Int(hours)) h")
                    .font(AppFont.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(theme.success)
            }
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}

/// The upcoming-service card (display-only; scheduling is Coming soon).
struct NextServiceCard: View {
    @Environment(\.appTheme) private var theme
    let item: MaintenanceItem

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("maintenance.next_service").instrumentLabel(theme.warning)
                    Spacer()
                    ComingSoonBadge()
                }
                Text(item.title).font(AppFont.headline).foregroundStyle(theme.ink)
                Text(nextSummary).font(AppFont.subheadline).foregroundStyle(theme.inkSecondary)
            }
            .padding(.vertical, 2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(theme.warning.opacity(0.4), lineWidth: 1)
        )
    }

    private var nextSummary: String {
        var parts: [String] = []
        if let h = item.nextServiceHours { parts.append(String(format: String(localized: "maintenance.in_hours"), Int(h))) }
        if let d = item.nextServiceDate { parts.append(String(format: String(localized: "maintenance.by_date"), d.shortDate)) }
        return parts.joined(separator: " · ")
    }
}

#Preview("Maintenance") {
    NavigationStack {
        MaintenanceView()
            .environment(\.appTheme, .paper)
            .modelContainer(PreviewData.container)
    }
}
