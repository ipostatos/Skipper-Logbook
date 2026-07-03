import SwiftUI
import SwiftData
import MapKit

/// Detail for a past voyage: a track map, key figures, and its log entries.
/// Route replay (animated playback) is marked Coming soon.
struct VoyageDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    let voyageID: PersistentIdentifier

    @State private var csvURL: URL?
    @State private var gpxURL: URL?

    private var voyage: Voyage? { context.model(for: voyageID) as? Voyage }

    var body: some View {
        ScrollView {
            if let voyage {
                VStack(spacing: Spacing.md) {
                    trackMap(voyage)
                    figures(voyage)
                    replayButton
                    entries(voyage)
                }
                .padding(.horizontal, Spacing.pageMargin)
                .padding(.bottom, Spacing.tabBarClearance)
            } else {
                EmptyStateView(symbol: "sailboat", title: "voyage.missing")
            }
        }
        .background(theme.background)
        .navigationTitle(voyage?.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if csvURL != nil || gpxURL != nil {
                    Menu {
                        if let csvURL {
                            ShareLink(item: csvURL) {
                                Label("voyage.export_csv", systemImage: "tablecells")
                            }
                        }
                        if let gpxURL {
                            ShareLink(item: gpxURL) {
                                Label("voyage.export_gpx", systemImage: "map")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task(id: voyageID) {
            guard let voyage else { return }
            csvURL = try? ExportService.writeCSV(for: voyage)
            gpxURL = try? ExportService.writeGPX(for: voyage)
        }
    }

    private func trackMap(_ voyage: Voyage) -> some View {
        let coords = voyage.orderedTrack.map { $0.coordinate.clCoordinate }
        return Card(padding: 0) {
            Map(initialPosition: .automatic, interactionModes: [.pan, .zoom]) {
                if coords.count > 1 {
                    MapPolyline(coordinates: coords).stroke(theme.accent, lineWidth: 3)
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
        }
    }

    private func figures(_ voyage: Voyage) -> some View {
        Card {
            StatGrid(tiles: [
                .init(symbol: "point.topleft.down.to.point.bottomright.curvepath",
                      label: "logbook.distance", value: voyage.distanceNM.oneDecimal, unit: "nm"),
                .init(symbol: "clock", label: "logbook.duration", value: voyage.elapsed.durationDHM),
                .init(symbol: "water.waves", label: "dash.avg_speed",
                      value: voyage.averageSpeedKn.oneDecimal, unit: "kn"),
                .init(symbol: "engine.combustion", label: "logbook.engine",
                      value: voyage.engineHours.oneDecimal, unit: "h")
            ], columns: 2)
        }
    }

    private var replayButton: some View {
        PrimaryButton(title: "voyage.replay", symbol: "play.circle", role: .neutral) {}
            .comingSoon()
    }

    private func entries(_ voyage: Voyage) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader("voyage.log")
            Card(padding: Spacing.xxs) {
                VStack(spacing: 0) {
                    let events = voyage.orderedEvents
                    ForEach(Array(events.enumerated()), id: \.element.id) { i, event in
                        LogEventRow(event: event)
                        if i < events.count - 1 { Divider().overlay(theme.hairline) }
                    }
                }
            }
        }
    }
}
