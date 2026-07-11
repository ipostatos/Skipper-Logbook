import SwiftUI
import WidgetKit

/// A minimal palette for the widgets — mirrors the app's Liquid Nautical accents
/// without depending on the app's theme system (widgets adapt to the system
/// light/dark automatically via semantic backgrounds).
enum WidgetPalette {
    static let blue = Color(red: 0.231, green: 0.424, blue: 1.0)
    static let cyan = Color(red: 0.157, green: 0.780, blue: 0.847)
    static let purple = Color(red: 0.431, green: 0.416, blue: 0.973)
    static let green = Color(red: 0.224, green: 0.851, blue: 0.541)
    static let orange = Color(red: 1.0, green: 0.702, blue: 0.251)
    static let red = Color(red: 1.0, green: 0.231, blue: 0.188)
}

/// One timeline entry carrying a voyage snapshot.
struct VoyageEntry: TimelineEntry {
    let date: Date
    let snapshot: VoyageSnapshot
}

/// Provider that reads the shared snapshot the app publishes. Refreshes every
/// few minutes (WidgetKit also reloads on `reloadAllTimelines`).
struct VoyageProvider: TimelineProvider {
    func placeholder(in context: Context) -> VoyageEntry {
        VoyageEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VoyageEntry) -> Void) {
        let snap = context.isPreview ? .placeholder : SharedStore.read()
        completion(VoyageEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoyageEntry>) -> Void) {
        let snap = SharedStore.read()
        let entry = VoyageEntry(date: .now, snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

extension Double {
    var oneDecimalW: String { String(format: "%.1f", self) }
}

/// A small labelled metric used inside widgets. The label is a catalog key
/// (EN literal doubles as the key) so widgets localize like the app.
struct WidgetMetric: View {
    let value: String
    let unit: String?
    let label: LocalizedStringKey
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint).monospacedDigit()
                if let unit { Text(unit).font(.caption2).foregroundStyle(.secondary) }
            }
            Text(label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
}
