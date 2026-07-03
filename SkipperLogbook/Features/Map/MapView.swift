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
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) { header }
            .overlay(alignment: .trailing) { controls }

            if let voyage, voyage.destination != nil {
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
