import WidgetKit
import SwiftUI

/// The main widget: active voyage at a glance. Small = speed/course/distance;
/// Medium = route + metrics + progress; Large = full captain dashboard; plus
/// Lock Screen (accessory) variants.
struct ActiveVoyageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ActiveVoyageWidget", provider: VoyageProvider()) { entry in
            ActiveVoyageWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Active Voyage")
        .description("Speed, course, distance and ETA at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryInline
        ])
    }
}

struct ActiveVoyageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VoyageEntry
    private var s: VoyageSnapshot { entry.snapshot }

    var body: some View {
        switch family {
        case .systemSmall:        small
        case .systemMedium:       medium
        case .systemLarge:        large
        case .accessoryRectangular: rectangular
        case .accessoryInline:    inline
        default:                  small
        }
    }

    // MARK: System small

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(s.speedKn.oneDecimalW).font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit()
                Text("kn").font(.caption).foregroundStyle(.secondary)
            }
            Text("\(Int(s.courseDegrees))° · \(s.distanceNM.oneDecimalW) nm")
                .font(.caption).foregroundStyle(.secondary)
            recordingLabel
        }
    }

    // MARK: System medium

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(spacing: 16) {
                WidgetMetric(value: s.speedKn.oneDecimalW, unit: "kn", label: "Speed", tint: WidgetPalette.blue)
                WidgetMetric(value: "\(Int(s.courseDegrees))°", unit: nil, label: "Course", tint: WidgetPalette.cyan)
                WidgetMetric(value: s.remainingNM.map { $0.oneDecimalW } ?? "—", unit: "nm", label: "To WP", tint: WidgetPalette.purple)
                if let eta = s.etaEpoch {
                    WidgetMetric(value: etaString(eta), unit: nil, label: "ETA", tint: .primary)
                }
            }
            progressBar
        }
    }

    // MARK: System large

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(s.courseDegrees))").font(.system(size: 52, weight: .bold, design: .rounded)).monospacedDigit()
                Text("° course").font(.headline).foregroundStyle(.secondary)
            }
            HStack(spacing: 20) {
                WidgetMetric(value: s.speedKn.oneDecimalW, unit: "kn", label: "Speed", tint: WidgetPalette.blue)
                WidgetMetric(value: s.distanceNM.oneDecimalW, unit: "nm", label: "Logged", tint: WidgetPalette.cyan)
                WidgetMetric(value: s.remainingNM.map { $0.oneDecimalW } ?? "—", unit: "nm", label: "Remaining", tint: WidgetPalette.purple)
            }
            HStack(spacing: 20) {
                if let f = s.fuelPercent {
                    WidgetMetric(value: "\(Int(f))", unit: "%", label: "Fuel", tint: WidgetPalette.orange)
                }
                if let eta = s.etaEpoch {
                    WidgetMetric(value: etaString(eta), unit: nil, label: "ETA", tint: .primary)
                }
            }
            Spacer(minLength: 0)
            progressBar
        }
    }

    // MARK: Lock Screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(s.voyageName.isEmpty ? "Skipper Logbook" : s.voyageName)
                .font(.headline).lineLimit(1)
            Text("\(s.speedKn.oneDecimalW) kn · \(Int(s.courseDegrees))°" +
                 (s.remainingNM.map { " · \($0.oneDecimalW) nm" } ?? ""))
                .font(.caption)
        }
    }

    private var inline: some View {
        Text("\(s.speedKn.oneDecimalW) kn · \(Int(s.courseDegrees))°" + (s.isRecording ? " · REC" : ""))
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "sailboat.fill").font(.caption).foregroundStyle(WidgetPalette.blue)
            Text(s.voyageName.isEmpty ? "No voyage" : s.voyageName)
                .font(.caption.weight(.semibold)).lineLimit(1)
            Spacer()
        }
    }

    private var recordingLabel: some View {
        Group {
            if s.isRecording {
                HStack(spacing: 4) {
                    Circle().fill(WidgetPalette.green).frame(width: 6, height: 6)
                    Text("Recording").font(.system(size: 9, weight: .medium)).foregroundStyle(WidgetPalette.green)
                }
            }
        }
    }

    private var progressBar: some View {
        Group {
            if let remaining = s.remainingNM {
                let total = s.distanceNM + remaining
                let frac = total > 0 ? s.distanceNM / total : 0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.2)).frame(height: 5)
                        Capsule().fill(WidgetPalette.blue).frame(width: geo.size.width * frac, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
    }

    private func etaString(_ epoch: Double) -> String {
        let date = Date(timeIntervalSince1970: epoch)
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
