import SwiftUI
import SwiftData
import MapKit

/// Detail for a past voyage: a track map, key figures, and its log entries.
/// Route replay (animated playback) is marked Coming soon.
struct VoyageDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let voyageID: PersistentIdentifier

    @State private var exportItem: ExportItem?
    @State private var confirmDelete = false

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
                // Files are generated at tap time, so a still-recording voyage
                // exports its current state, never a view-appear snapshot.
                if let voyage {
                    Menu {
                        Button {
                            exportItem = (try? ExportService.writeCSV(for: voyage)).map(ExportItem.init)
                        } label: {
                            Label("voyage.export_csv", systemImage: "tablecells")
                        }
                        Button {
                            exportItem = (try? ExportService.writeGPX(for: voyage)).map(ExportItem.init)
                        } label: {
                            Label("voyage.export_gpx", systemImage: "map")
                        }
                        // A still-recording voyage can't be deleted — the
                        // recorder holds a live reference; stop it first.
                        if !voyage.isRecording {
                            Divider()
                            Button(role: .destructive) { confirmDelete = true } label: {
                                Label("voyage.delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(item: $exportItem) { item in
            ShareSheet(items: [item.url])
        }
        .confirmationDialog("voyage.delete_confirm", isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("voyage.delete", role: .destructive) { deleteVoyage() }
            Button("common.cancel", role: .cancel) {}
        }
    }

    private func deleteVoyage() {
        guard let voyage else { return }
        // The cascade removes VoiceNote ROWS, not their .m4a files — sweep the
        // audio first or it leaks in Documents forever.
        for note in voyage.voiceNotes { note.deleteAudioFile() }
        context.delete(voyage)
        try? context.save()
        dismiss()
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

/// Identifiable wrapper so `.sheet(item:)` can present a freshly written file.
private struct ExportItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Thin UIKit bridge — `ShareLink` needs its URL up front, but we only want to
/// build the file when the user actually asks for it.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
