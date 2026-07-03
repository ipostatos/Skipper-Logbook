import SwiftUI

/// A rich logbook row mirroring the screenshots: time · heading · leg-distance
/// on the top line; the event/sail summary; an optional free-text note; and a
/// position + wind footer.
struct LogEventRow: View {
    @Environment(\.appTheme) private var theme
    let event: LogEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top line: time / heading / distance
            HStack {
                Text(event.timestamp.hourMinute())
                    .font(AppFont.mono(.subheadline))
                    .foregroundStyle(theme.ink)
                Spacer()
                if let heading = event.headingDegrees {
                    Text("\(Int(heading))°")
                        .font(AppFont.mono(.footnote))
                        .foregroundStyle(theme.inkSecondary)
                }
                Spacer()
                if let dist = event.legDistanceNM {
                    Text("\(dist.oneDecimal)nm")
                        .font(AppFont.mono(.footnote))
                        .foregroundStyle(theme.inkSecondary)
                }
            }

            // Event summary line (icon + title + sail state)
            HStack(spacing: Spacing.xs) {
                Image(systemName: event.type.symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(event.type.tint.color(theme))
                Text(event.type.titleKey)
                    .font(AppFont.subheadline.weight(.medium))
                    .foregroundStyle(theme.ink)
                if event.hasSailState {
                    sailSummary
                }
                Spacer()
            }

            // Free-text note
            if let note = event.note, !note.isEmpty {
                Text(note)
                    .font(AppFont.footnote)
                    .foregroundStyle(theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Footer: position + wind
            HStack(spacing: Spacing.sm) {
                if let coord = event.coordinate {
                    Label(CoordinateFormatting.string(coord), systemImage: "location")
                        .font(AppFont.mono(.caption2))
                        .foregroundStyle(theme.inkTertiary)
                        .labelStyle(.titleAndIcon)
                }
                Spacer()
                if let wind = event.windSummary {
                    Label(wind, systemImage: "wind")
                        .font(AppFont.caption2)
                        .foregroundStyle(theme.inkSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var sailSummary: some View {
        HStack(spacing: 6) {
            if let m = event.mainsailPercent {
                sailTag(symbol: "sailboat.fill", value: "\(m)%")
            }
            if let j = event.jibPercent {
                sailTag(symbol: "sailboat", value: "\(j)%")
            }
        }
    }

    private func sailTag(symbol: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 11))
            Text(value).font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()
        }
        .foregroundStyle(theme.sail)
    }
}

#Preview("Log rows") {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(PreviewData.sampleVoyage.orderedEvents) { e in
                LogEventRow(event: e)
                Divider()
            }
        }
    }
    .environment(\.appTheme, .night)
    .background(Color(hex: "0B1626"))
    .modelContainer(PreviewData.container)
}
