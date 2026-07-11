import WidgetKit
import SwiftUI

/// Maintenance reminder widget for the boat owner — next service + hours left.
struct MaintenanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MaintenanceWidget", provider: VoyageProvider()) { entry in
            MaintenanceWidgetView(snapshot: entry.snapshot)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Maintenance")
        .description("Next service reminder, based on engine hours.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct MaintenanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: VoyageSnapshot

    var body: some View {
        if family == .accessoryRectangular {
            VStack(alignment: .leading, spacing: 2) {
                Label(snapshot.nextServiceTitle ?? String(localized: "Service"), systemImage: "wrench.and.screwdriver.fill")
                    .font(.headline).lineLimit(1)
                if let h = snapshot.nextServiceHoursLeft {
                    Text("in \(Int(h)) h").font(.caption)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title3).foregroundStyle(WidgetPalette.orange)
                Spacer(minLength: 0)
                Text(snapshot.nextServiceTitle ?? String(localized: "No service due"))
                    .font(.headline).lineLimit(2)
                if let h = snapshot.nextServiceHoursLeft {
                    Text("in \(Int(h)) engine hours")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Logbook streak widget — voyages & miles this month (motivational, Fitness-like).
struct LogbookStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LogbookStreakWidget", provider: VoyageProvider()) { entry in
            StreakWidgetView(snapshot: entry.snapshot)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Logbook")
        .description("Your voyages and miles this month.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetView: View {
    let snapshot: VoyageSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill").foregroundStyle(WidgetPalette.purple)
                Text("Logbook").font(.caption.weight(.semibold))
            }
            Spacer(minLength: 0)
            Text("\(snapshot.voyagesThisMonth)")
                .font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
            Text("voyages recorded").font(.caption2).foregroundStyle(.secondary)
            Text("\(Int(snapshot.milesThisMonth)) nm this month")
                .font(.caption2).foregroundStyle(WidgetPalette.blue)
        }
    }
}
