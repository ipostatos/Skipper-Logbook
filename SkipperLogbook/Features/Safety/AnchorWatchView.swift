import SwiftUI
import Darwin

/// Anchor watch: drop the anchor at the current position, set an alarm radius,
/// and monitor distance-from-anchor + max deviation on a live drift circle.
/// Presented as a sheet from the quick actions.
struct AnchorWatchView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var location
    @Environment(AnchorWatchEngine.self) private var engine

    @State private var radius: Double = 15
    @State private var now: Date = .now

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if engine.isActive {
                        activeContent
                    } else {
                        setupContent
                    }
                }
                .padding(.horizontal, Spacing.pageMargin)
                .padding(.vertical, Spacing.md)
            }
            .background(theme.background)
            .navigationTitle("anchor.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .onReceive(ticker) { now = $0 }
        }
    }

    // MARK: Not yet watching — configure & drop

    private var setupContent: some View {
        VStack(spacing: Spacing.md) {
            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("anchor.setup_hint")
                        .font(AppFont.subheadline).foregroundStyle(theme.inkSecondary)
                    HStack {
                        Text("anchor.radius").font(AppFont.subheadline).foregroundStyle(theme.ink)
                        Spacer()
                        Text("\(Int(radius)) m")
                            .font(AppFont.statNumeral.monospacedDigit()).foregroundStyle(theme.ink)
                    }
                    Slider(value: $radius, in: 10...80, step: 5)
                    if let coord = location.currentCoordinate {
                        Text(CoordinateFormatting.string(coord))
                            .font(AppFont.mono(.footnote)).foregroundStyle(theme.inkSecondary)
                    }
                }
            }
            PrimaryButton(title: "anchor.drop", symbol: "anchor.fill", role: .accent) {
                guard let coord = location.currentCoordinate else { return }
                engine.start(at: coord, radiusMeters: radius)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            .disabled(location.currentCoordinate == nil)

            // Honest about the limitation: with the screen locked, the alarm
            // needs Always location; otherwise keep the app open.
            Text("anchor.background_hint")
                .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Watching — live status + drift circle

    private var activeContent: some View {
        let dragging = engine.isDragging
        return VStack(spacing: Spacing.md) {
            // Status header
            HStack {
                Label(dragging ? "anchor.dragging" : "anchor.holding",
                      systemImage: dragging ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(AppFont.headline)
                    .foregroundStyle(dragging ? theme.danger : theme.success)
                Spacer()
                Text(engine.elapsed.stopwatchHMS)
                    .font(AppFont.mono(.subheadline)).foregroundStyle(theme.ink)
            }

            // Distance / deviation
            Card {
                HStack {
                    metric("\(Int(engine.currentDistanceMeters)) m", "anchor.distance",
                           tint: dragging ? theme.danger : theme.ink)
                    Spacer()
                    metric("\(Int(engine.session?.maxDeviationMeters ?? 0)) m", "anchor.max_deviation")
                }
            }

            // Drift circle
            DriftCircleView(radiusMeters: engine.session?.radiusMeters ?? radius,
                            boatOffset: boatOffset,
                            trail: trailOffsets,
                            heading: location.effectiveHeading,
                            isDragging: dragging)
                .frame(height: 280)

            Text(String(format: String(localized: "anchor.radius_footer"),
                        Int(engine.session?.radiusMeters ?? radius)))
                .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)

            if engine.alarmNotificationsAuthorized == false {
                Label("anchor.notifications_denied", systemImage: "bell.slash")
                    .font(AppFont.footnote)
                    .foregroundStyle(theme.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "anchor.stop", symbol: "stop.circle", role: .danger) {
                engine.stop()
            }
        }
    }

    private func metric(_ value: String, _ label: LocalizedStringKey, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.headingNumeral).foregroundStyle(tint ?? theme.ink).monospacedDigit()
            Text(label).instrumentLabel(theme.inkSecondary)
        }
    }

    // MARK: Geometry helpers — metre offsets (east, north) from the anchor

    private var boatOffset: CGPoint {
        guard let anchor = engine.session?.anchor, let boat = location.currentCoordinate else { return .zero }
        return offset(from: anchor, to: boat)
    }

    private var trailOffsets: [CGPoint] {
        guard let anchor = engine.session?.anchor else { return [] }
        return engine.trail.map { offset(from: anchor, to: $0) }
    }

    private func offset(from anchor: GeoCoordinate, to point: GeoCoordinate) -> CGPoint {
        let distance = NavigationMath.haversineMeters(anchor, point)
        let bearing = NavigationMath.initialBearingDegrees(from: anchor, to: point)
        let rad = NavigationMath.degreesToRadians(bearing)
        return CGPoint(x: distance * Darwin.sin(rad), y: distance * Darwin.cos(rad)) // east, north
    }
}

#Preview("Anchor watch") {
    AnchorWatchView()
        .environment(\.appTheme, .night)
        .environment(LocationManager())
        .environment(AnchorWatchEngine(context: PreviewData.container.mainContext))
        .modelContainer(PreviewData.container)
}
