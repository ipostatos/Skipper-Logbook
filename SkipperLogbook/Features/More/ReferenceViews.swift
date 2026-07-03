import SwiftUI
import SwiftData

// MARK: - Equipment list

/// Onboard equipment / inventory with optional expiry (raft, flares, EPIRB…).
struct EquipmentListView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \EquipmentItem.name) private var items: [EquipmentItem]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if items.isEmpty {
                    EmptyStateView(symbol: "shippingbox", title: "equipment.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                                equipmentRow(item)
                                if i < items.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.equipment")
        .navigationBarTitleDisplayMode(.large)
    }

    private func equipmentRow(_ item: EquipmentItem) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(AppFont.subheadline).foregroundStyle(theme.ink)
                if let detail = item.detail {
                    Text(detail).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("×\(item.quantity)").font(AppFont.subheadline.monospacedDigit()).foregroundStyle(theme.ink)
                if let exp = item.expiresAt {
                    Text(exp.shortDate).font(AppFont.caption)
                        .foregroundStyle(exp < .now ? theme.danger : theme.inkSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Service notes

struct ServiceNotesView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \ServiceNote.createdAt, order: .reverse) private var notes: [ServiceNote]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if notes.isEmpty {
                    EmptyStateView(symbol: "book.closed", title: "service_notes.empty")
                } else {
                    ForEach(notes) { note in
                        Card {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(note.title).font(AppFont.headline).foregroundStyle(theme.ink)
                                    Spacer()
                                    Text(note.createdAt.shortDate).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                                }
                                Text(note.body).font(AppFont.subheadline).foregroundStyle(theme.inkSecondary)
                                if let h = note.engineHours {
                                    Text(String(format: String(localized: "service_notes.at_hours"), h.oneDecimal))
                                        .font(AppFont.caption).foregroundStyle(theme.inkTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.service_notes")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Season log

struct SeasonLogView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \SeasonLogEntry.startedAt, order: .reverse) private var seasons: [SeasonLogEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if seasons.isEmpty {
                    EmptyStateView(symbol: "sun.max", title: "season.empty")
                } else {
                    ForEach(seasons) { season in
                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(season.seasonName).font(AppFont.display(24)).foregroundStyle(theme.ink)
                                HStack(spacing: Spacing.xl) {
                                    metric("\(season.totalDistanceNM.oneDecimal) nm", "season.distance")
                                    metric("\(season.engineHours.oneDecimal) h", "season.engine")
                                }
                                if let notes = season.notes {
                                    Text(notes).font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.season_log")
        .navigationBarTitleDisplayMode(.large)
    }

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink)
            Text(label).instrumentLabel(theme.inkSecondary)
        }
    }
}

// MARK: - Deviation table

struct DeviationView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \DeviationEntry.headingDegrees) private var entries: [DeviationEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("deviation.hint").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entries.isEmpty {
                    EmptyStateView(symbol: "location.north.circle", title: "deviation.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            headerRow
                            Divider().overlay(theme.hairline)
                            ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                                deviationRow(entry)
                                if i < entries.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.deviation")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerRow: some View {
        HStack {
            Text("deviation.heading").instrumentLabel(theme.inkSecondary)
            Spacer()
            Text("deviation.value").instrumentLabel(theme.inkSecondary)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }

    private func deviationRow(_ entry: DeviationEntry) -> some View {
        HStack {
            Text("\(Int(entry.headingDegrees))°")
                .font(AppFont.mono(.subheadline)).foregroundStyle(theme.ink)
            Spacer()
            let d = entry.deviationDegrees
            Text("\(d >= 0 ? "+" : "")\(Int(d))° \(d >= 0 ? "E" : "W")")
                .font(AppFont.mono(.subheadline))
                .foregroundStyle(d == 0 ? theme.inkSecondary : theme.accent)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}
