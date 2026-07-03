import SwiftUI
import SwiftData
import MapKit
import Charts

/// Voyage statistics: a track map, a speed-over-time chart, and the propulsion
/// breakdown (distance by Engine / Sails / Sails & Engine / Idle) with a donut.
/// Export/share of stats is marked Coming soon.
struct StatisticsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(VoyageRecorder.self) private var recorder
    @Query(sort: \Voyage.startedAt, order: .reverse) private var voyages: [Voyage]

    private var voyage: Voyage? { recorder.activeVoyage ?? voyages.first }

    var body: some View {
        ScrollView {
            if let voyage {
                let stats = VoyageStatistics(voyage: voyage)
                VStack(spacing: Spacing.md) {
                    trackMap(voyage)
                    speedChart(stats)
                    breakdown(stats)
                }
                .padding(.horizontal, Spacing.pageMargin)
                .padding(.bottom, Spacing.tabBarClearance)
            } else {
                EmptyStateView(symbol: "chart.bar", title: "stats.empty_title",
                               message: "stats.empty_message")
            }
        }
        .background(theme.background)
        .navigationTitle("stats.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: { Image(systemName: "square.and.arrow.up") }
                    .comingSoon()
            }
        }
    }

    // MARK: Track map

    private func trackMap(_ voyage: Voyage) -> some View {
        let coords = voyage.orderedTrack.map { $0.coordinate.clCoordinate }
        return Card(padding: 0) {
            Map(initialPosition: .automatic, interactionModes: []) {
                if coords.count > 1 {
                    MapPolyline(coordinates: coords)
                        .stroke(theme.accent, lineWidth: 3)
                    if let start = coords.first {
                        Marker("stats.start", systemImage: "flag", coordinate: start).tint(theme.success)
                    }
                    if let end = coords.last {
                        Marker("stats.finish", systemImage: "flag.checkered", coordinate: end).tint(theme.danger)
                    }
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .allowsHitTesting(false)
        }
    }

    // MARK: Speed chart

    private func speedChart(_ stats: VoyageStatistics) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    SectionHeader("stats.speed")
                    Spacer()
                    Text("\(stats.maxSpeedKn.oneDecimal) kn max")
                        .font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                }
                Chart(stats.speedSeries) { sample in
                    LineMark(x: .value("Time", sample.time),
                             y: .value("Speed", sample.speedKn))
                    .foregroundStyle(theme.accent)
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...(max(stats.maxSpeedKn, 5) * 1.15))
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 160)
            }
        }
    }

    // MARK: Propulsion breakdown

    private func breakdown(_ stats: VoyageStatistics) -> some View {
        Card {
            HStack(alignment: .center, spacing: Spacing.lg) {
                Chart(stats.slices.filter { $0.distanceNM > 0 }) { slice in
                    SectorMark(angle: .value("Distance", slice.distanceNM),
                               innerRadius: .ratio(0.55), angularInset: 1.5)
                    .foregroundStyle(color(for: slice.mode))
                    .cornerRadius(2)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(stats.slices) { slice in
                        HStack(spacing: Spacing.xs) {
                            Circle().fill(color(for: slice.mode)).frame(width: 9, height: 9)
                            Image(systemName: slice.mode.symbol)
                                .font(.system(size: 12)).foregroundStyle(theme.inkSecondary)
                            Text(LocalizedStringKey(slice.mode.titleKey))
                                .font(AppFont.footnote).foregroundStyle(theme.ink)
                            Spacer(minLength: Spacing.sm)
                            Text("\(slice.distanceNM.oneDecimal)nm (\(Int(slice.fraction * 100))%)")
                                .font(AppFont.caption.monospacedDigit())
                                .foregroundStyle(theme.inkSecondary)
                        }
                    }
                }
            }
        }
    }

    private func color(for mode: PropulsionMode) -> Color {
        switch mode {
        case .engine:         return theme.warning
        case .sails:          return theme.accent
        case .sailsAndEngine: return theme.success
        case .idle:           return theme.inkTertiary
        }
    }
}

#Preview("Statistics") {
    NavigationStack {
        StatisticsView()
            .environment(\.appTheme, .night)
            .environment(VoyageRecorder(context: PreviewData.container.mainContext))
            .modelContainer(PreviewData.container)
            .background(Color(hex: "0B1626"))
    }
}
