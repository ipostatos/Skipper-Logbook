import SwiftUI
import SwiftData

/// Detail for a single log entry: title, date/position, a metric grid
/// (speed / course / wind / engine), sail state, and the free-text note.
struct LogEntryDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    let eventID: PersistentIdentifier

    private var event: LogEvent? {
        context.model(for: eventID) as? LogEvent
    }

    var body: some View {
        ScrollView {
            if let event {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    header(event)
                    metricGrid(event)
                    if event.hasSailState { sailCard(event) }
                    if let note = event.note, !note.isEmpty { noteCard(note) }
                }
                .padding(.horizontal, Spacing.pageMargin)
                .padding(.bottom, Spacing.tabBarClearance)
            } else {
                EmptyStateView(symbol: "questionmark.circle", title: "logbook.entry_missing")
            }
        }
        .background(theme.background)
        .navigationTitle("logbook.entry_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ event: LogEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(event.timestamp.logDayHeader()) · \(event.timestamp.hourMinute())")
                .instrumentLabel(theme.inkSecondary)
            HStack(spacing: Spacing.xs) {
                Image(systemName: event.type.symbol)
                    .foregroundStyle(event.type.tint.color(theme))
                Text(event.type.titleKey)
                    .font(AppFont.display(28))
                    .foregroundStyle(theme.ink)
            }
            if let coord = event.coordinate {
                Text(CoordinateFormatting.string(coord))
                    .font(AppFont.mono(.footnote))
                    .foregroundStyle(theme.inkSecondary)
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func metricGrid(_ event: LogEvent) -> some View {
        Card {
            let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
                metric("logbook.speed", event.speedKnots.map { "\($0.oneDecimal) kn" } ?? "—")
                metric("logbook.course", event.headingDegrees.map { "\(Int($0))°" } ?? "—")
                metric("logbook.wind", event.windSummary ?? "—")
                metric("logbook.leg", event.legDistanceNM.map { "\($0.oneDecimal) nm" } ?? "—")
            }
        }
    }

    private func metric(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).instrumentLabel(theme.inkSecondary)
            Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink)
        }
    }

    private func sailCard(_ event: LogEvent) -> some View {
        Card {
            HStack(spacing: Spacing.xl) {
                if let m = event.mainsailPercent {
                    sail("status.mainsail", "\(m)%")
                }
                if let j = event.jibPercent {
                    sail("status.jib", "\(j)%")
                }
                Spacer()
            }
        }
    }

    private func sail(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).instrumentLabel(theme.inkSecondary)
            HStack(spacing: 4) {
                Image(systemName: "sailboat.fill").foregroundStyle(theme.sail)
                Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink)
            }
        }
    }

    private func noteCard(_ note: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text("event.note").instrumentLabel(theme.inkSecondary)
                Text(note).font(AppFont.body).foregroundStyle(theme.ink)
            }
        }
    }
}
