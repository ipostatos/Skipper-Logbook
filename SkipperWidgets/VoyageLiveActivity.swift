import WidgetKit
import SwiftUI
import ActivityKit

/// The active-voyage Live Activity: Lock Screen banner + Dynamic Island (compact
/// and expanded). Reads `VoyageActivityAttributes` updated by the app.
struct VoyageLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VoyageActivityAttributes.self) { context in
            // Lock Screen / banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.2))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.destination ?? context.attributes.voyageName)
                            .font(.caption).lineLimit(1)
                    } icon: {
                        Image(systemName: "sailboat.fill").foregroundStyle(WidgetPalette.blue)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isRecording {
                        HStack(spacing: 4) {
                            Circle().fill(WidgetPalette.green).frame(width: 6, height: 6)
                            Text("REC").font(.caption2.weight(.bold)).foregroundStyle(WidgetPalette.green)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 14) {
                        metric("\(context.state.speedKn.oneDecimalW)", "kn")
                        metric("\(Int(context.state.courseDegrees))°", nil)
                        if let r = context.state.remainingNM { metric("\(r.oneDecimalW)", "nm") }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    progressBar(context.state.progress)
                }
            } compactLeading: {
                Image(systemName: "sailboat.fill").foregroundStyle(WidgetPalette.blue)
            } compactTrailing: {
                Text("\(context.state.speedKn.oneDecimalW)kn")
                    .font(.caption2).monospacedDigit()
            } minimal: {
                Image(systemName: "sailboat.fill").foregroundStyle(WidgetPalette.blue)
            }
        }
    }

    private func metric(_ value: String, _ unit: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value).font(.system(size: 15, weight: .semibold, design: .rounded)).monospacedDigit()
            if let unit { Text(unit).font(.caption2).foregroundStyle(.secondary) }
        }
    }

    private func progressBar(_ frac: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.25)).frame(height: 5)
                Capsule().fill(WidgetPalette.blue).frame(width: geo.size.width * frac, height: 5)
            }
        }
        .frame(height: 5)
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<VoyageActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(routeTitle).font(.headline).lineLimit(1)
                } icon: {
                    Image(systemName: "sailboat.fill").foregroundStyle(WidgetPalette.blue)
                }
                Spacer()
                if context.state.isRecording {
                    HStack(spacing: 4) {
                        Circle().fill(WidgetPalette.green).frame(width: 7, height: 7)
                        Text("REC").font(.caption2.weight(.bold)).foregroundStyle(WidgetPalette.green)
                    }
                }
            }
            HStack(spacing: 20) {
                metric("\(context.state.speedKn.oneDecimalW)", "kn", "Speed")
                metric("\(Int(context.state.courseDegrees))°", nil, "Course")
                if let r = context.state.remainingNM { metric("\(r.oneDecimalW)", "nm", "To WP") }
                if let eta = context.state.etaEpoch { metric(etaString(eta), nil, "ETA") }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.25)).frame(height: 5)
                    Capsule().fill(WidgetPalette.blue).frame(width: geo.size.width * context.state.progress, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding()
    }

    private var routeTitle: String {
        if let o = context.attributes.origin, let d = context.attributes.destination {
            return "\(o) → \(d)"
        }
        return context.attributes.destination ?? context.attributes.voyageName
    }

    private func metric(_ value: String, _ unit: String?, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 17, weight: .semibold, design: .rounded)).monospacedDigit()
                if let unit { Text(unit).font(.caption2).foregroundStyle(.secondary) }
            }
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary).textCase(.uppercase)
        }
    }

    private func etaString(_ epoch: Double) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: Date(timeIntervalSince1970: epoch))
    }
}
