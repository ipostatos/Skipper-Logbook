import SwiftUI
import MapKit
import SwiftData

/// The Map tab — Apple-Maps-light nautical feel (never a dark Navionics look).
/// Shows the sailed track (cyan), the planned route to the waypoint (dashed
/// purple), the boat, waypoint & MOB markers, plus a floating voyage header,
/// a next-waypoint card, and recenter / layer controls. Screen accent: cyan.
struct MapView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(MOBEngine.self) private var mob

    @Query(sort: \Voyage.startedAt, order: .reverse) private var voyages: [Voyage]
    @State private var camera: MapCameraPosition = .automatic
    @State private var hybrid = false
    /// Add-waypoint mode: the next tap on the chart sets the active voyage's
    /// destination. Only offered while a voyage is recording.
    @State private var settingWaypoint = false
    @State private var mobNoFix = false

    private var voyage: Voyage? { recorder.activeVoyage ?? voyages.first }
    private var track: [CLLocationCoordinate2D] {
        (voyage?.orderedTrack ?? []).map { $0.coordinate.clCoordinate }
    }
    private var routeLine: [CLLocationCoordinate2D]? {
        guard let dest = voyage?.destination?.clCoordinate,
              let here = location.currentCoordinate?.clCoordinate ?? track.last else { return nil }
        return [here, dest]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapReader { proxy in
                Map(position: $camera) {
                    UserAnnotation()

                    // Planned route (dashed purple)
                    if let route = routeLine {
                        MapPolyline(coordinates: route)
                            .stroke(theme.purple, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    }
                    // Sailed track (solid cyan)
                    if track.count > 1 {
                        MapPolyline(coordinates: track)
                            .stroke(theme.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                    // Waypoint dot
                    if let dest = voyage?.destination {
                        Annotation(voyage?.destinationName ?? String(localized: "map.waypoint"),
                                   coordinate: dest.clCoordinate) {
                            waypointDot
                        }
                    }
                    // MOB marker
                    if let point = mob.activePoint {
                        Marker("map.mob", systemImage: "figure.wave", coordinate: point.coordinate.clCoordinate)
                            .tint(theme.danger)
                    }
                }
                .mapStyle(hybrid ? .hybrid(elevation: .flat)
                                 : .standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .mapControls { MapScaleView() }
                .onTapGesture { screenPoint in
                    guard settingWaypoint else { return }
                    if let coord = proxy.convert(screenPoint, from: .local) {
                        setWaypoint(GeoCoordinate(coord))
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) { header }
            .overlay(alignment: .trailing) { controls }

            if settingWaypoint {
                waypointHint
                    .padding(.horizontal, Spacing.pageMargin)
                    .padding(.bottom, Spacing.tabBarClearance)
            } else if let voyage, voyage.destination != nil {
                NextWaypointCard(voyage: voyage,
                                 from: location.currentCoordinate,
                                 speedMps: location.speedMps)
                    .padding(.horizontal, Spacing.pageMargin)
                    .padding(.bottom, Spacing.tabBarClearance)
            }
        }
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: recenter)
        .alert("mob.no_fix_title", isPresented: $mobNoFix) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("mob.no_fix_message") }
    }

    private var waypointDot: some View {
        ZStack {
            Circle().fill(theme.purple.opacity(0.25)).frame(width: 22, height: 22)
            Circle().fill(theme.purple).frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            if let voyage {
                Image(systemName: "location.north.line.fill").foregroundStyle(theme.cyan)
                Text(voyage.destinationName.map { "\(voyage.name) → \($0)" } ?? voyage.name)
                    .font(AppFont.headline).foregroundStyle(theme.ink).lineLimit(1)
            } else {
                Text("map.title").font(AppFont.headline).foregroundStyle(theme.ink)
            }
            Spacer()
            if recorder.isRecording {
                HStack(spacing: 5) {
                    Circle().fill(theme.danger).frame(width: 7, height: 7)
                    Text("logbook.recording").font(AppFont.caption.weight(.semibold)).foregroundStyle(theme.danger)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, Spacing.pageMargin)
        .padding(.top, Spacing.xs)
    }

    private var controls: some View {
        VStack(spacing: Spacing.sm) {
            mapButton("square.2.layers.3d") { hybrid.toggle() }
            mapButton("location.fill", action: recenter)
            // Add-waypoint only exists while a voyage records — a dead button
            // with no voyage would pretend to work.
            if recorder.activeVoyage != nil {
                mapButton(settingWaypoint ? "xmark" : "mappin.and.ellipse") {
                    settingWaypoint.toggle()
                }
            }
            mobHoldButton
        }
        .padding(.trailing, Spacing.pageMargin)
        .padding(.bottom, Spacing.tabBarClearance + 110)
    }

    private func mapButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.cyan)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.surface))
                .cardShadow(theme)
        }
        .buttonStyle(.plain)
    }

    /// Hold-to-activate MOB, same protection as the big Safety button.
    private var mobHoldButton: some View {
        ZStack {
            Circle().fill(theme.danger).frame(width: 44, height: 44)
            Text("MOB").font(.system(size: 10, weight: .heavy)).foregroundStyle(.white)
        }
        .cardShadow(theme)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: MOBButton.holdDuration) { triggerMOB() }
        .accessibilityLabel("Man overboard")
        .accessibilityHint(Text("safety.press_hold"))
    }

    private var waypointHint: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "hand.tap").foregroundStyle(theme.cyan)
            Text("map.tap_to_set_waypoint")
                .font(AppFont.footnote).foregroundStyle(theme.ink)
            Spacer()
            Button("common.cancel") { settingWaypoint = false }
                .font(AppFont.footnote.weight(.semibold))
                .foregroundStyle(theme.cyan)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: Actions

    private func setWaypoint(_ coordinate: GeoCoordinate) {
        settingWaypoint = false
        guard coordinate.isValid else { return }
        recorder.setDestination(coordinate,
                                from: location.currentCoordinate,
                                heading: location.effectiveHeading)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func triggerMOB() {
        if mob.trigger(from: location) {
            router.presentMOB()
        } else {
            mobNoFix = true
        }
    }

    private func recenter() {
        if let coord = location.currentCoordinate {
            camera = .region(MKCoordinateRegion(
                center: coord.clCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
        } else if track.count > 1 {
            camera = .automatic
        }
    }
}

#Preview("Map") {
    NavigationStack {
        MapView()
            .environment(\.appTheme, .light)
            .environment(AppRouter())
            .environment(LocationManager())
            .environment(VoyageRecorder(context: PreviewData.container.mainContext))
            .environment(MOBEngine(context: PreviewData.container.mainContext))
            .modelContainer(PreviewData.container)
    }
}
