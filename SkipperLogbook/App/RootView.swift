import SwiftUI
import SwiftData

/// The root tab shell. Hosts one `NavigationStack` per tab, the custom bottom
/// bar with a floating +, the quick-actions sheet, and the full-screen MOB
/// cover. It also fans live location fixes out to the recorder / anchor / MOB
/// engines so a single location stream drives everything.
struct RootView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(AnchorWatchEngine.self) private var anchorWatch
    @Environment(MOBEngine.self) private var mob
    @Environment(LiveActivityController.self) private var liveActivity
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var router = router

        ZStack(alignment: .bottom) {
            theme.background.ignoresSafeArea()

            // Active tab content
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom bar + centered floating +
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    CustomTabBar(selection: $router.selectedTab)
                    FloatingActionButton { router.present(.quickActions) }
                        .frame(maxWidth: .infinity)
                        .offset(y: -18)
                        .allowsHitTesting(true)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(item: $router.sheet) { route in
            sheetContent(route)
                .environment(\.appTheme, theme)
        }
        .fullScreenCover(item: $router.cover) { route in
            switch route {
            case .mobActive:
                MOBActiveView().environment(\.appTheme, theme)
            }
        }
        .onAppear { location.start(); syncWidgets() }
        .onChange(of: location.currentLocation) { _, newValue in
            guard let loc = newValue else { return }
            recorder.ingest(loc)
            anchorWatch.ingest(GeoCoordinate(loc.coordinate))
            mob.ingest(boat: GeoCoordinate(loc.coordinate))
            syncWidgets()
        }
        .onChange(of: recorder.isRecording) { _, _ in syncWidgets() }
    }

    /// Builds a snapshot from current state and pushes it to widgets + Live
    /// Activity. Cheap enough to call on each fix.
    private func syncWidgets() {
        let coord = location.currentCoordinate
        let voyage = recorder.activeVoyage
        let vessel = (try? modelContext.fetch(FetchDescriptor<Vessel>()))?.first
        let allVoyages = (try? modelContext.fetch(FetchDescriptor<Voyage>())) ?? []
        let remainingM = recorder.remainingDistanceMeters(from: coord)

        // This-month streak
        let cal = Calendar.current
        let monthVoyages = allVoyages.filter { cal.isDate($0.startedAt, equalTo: .now, toGranularity: .month) }
        let milesThisMonth = monthVoyages.reduce(0) { $0 + $1.distanceNM }

        // Soonest maintenance
        let maint = (try? modelContext.fetch(FetchDescriptor<MaintenanceItem>())) ?? []
        let nextService = maint.compactMap { item -> (String, Double)? in
            guard let hours = item.nextServiceHours, let done = item.engineHoursAtService else { return nil }
            return (item.title, max(0, hours - done))
        }.min { $0.1 < $1.1 }

        let snapshot = VoyageSnapshot(
            isRecording: recorder.isRecording,
            voyageName: voyage?.name ?? "",
            origin: nil,
            destination: voyage?.destinationName,
            speedKn: Units.mpsToKnots(location.speedMps),
            courseDegrees: location.effectiveHeading,
            distanceNM: voyage?.distanceNM ?? 0,
            remainingNM: remainingM.map(Units.metersToNM),
            etaEpoch: recorder.etaSeconds(from: coord, speedMps: location.speedMps)
                .map { Date.now.addingTimeInterval($0).timeIntervalSince1970 },
            fuelPercent: fuelPercent(vessel: vessel, voyage: voyage),
            nextServiceTitle: nextService?.0,
            nextServiceHoursLeft: nextService?.1,
            voyagesThisMonth: monthVoyages.count,
            milesThisMonth: milesThisMonth,
            updatedEpoch: 0
        )
        liveActivity.publish(snapshot)

        // Drive the Live Activity when recording.
        if recorder.isRecording {
            let progress = routeProgress(voyage: voyage, remainingM: remainingM)
            let state = VoyageActivityAttributes.ContentState(
                speedKn: snapshot.speedKn, courseDegrees: snapshot.courseDegrees,
                distanceNM: snapshot.distanceNM, remainingNM: snapshot.remainingNM,
                etaEpoch: snapshot.etaEpoch, progress: progress, isRecording: true)
            liveActivity.startActivity(name: snapshot.voyageName, origin: snapshot.origin,
                                       destination: snapshot.destination, state: state)
        } else {
            Task { await liveActivity.endActivity() }
        }
    }

    private func fuelPercent(vessel: Vessel?, voyage: Voyage?) -> Double? {
        guard let cap = vessel?.fuelCapacityLiters, cap > 0 else { return nil }
        let used = voyage?.fuelUsedLiters ?? 0
        return max(0, min(100, (cap - used) / cap * 100))
    }

    private func routeProgress(voyage: Voyage?, remainingM: Double?) -> Double {
        guard let planned = voyage?.plannedDistanceMeters, planned > 0,
              let remaining = remainingM else {
            // Fall back to distance-so-far vs. distance+remaining.
            let done = (voyage?.distanceMeters ?? 0)
            let rem = remainingM ?? 0
            let total = done + rem
            return total > 0 ? min(1, done / total) : 0
        }
        return min(1, max(0, 1 - remaining / planned))
    }

    // MARK: Tab content — each tab is its own navigation stack

    @ViewBuilder
    private var tabContent: some View {
        @Bindable var router = router
        switch router.selectedTab {
        case .today:
            NavigationStack(path: $router.todayPath) {
                TodayView().withAppRoutes()
            }
        case .map:
            NavigationStack(path: $router.mapPath) {
                MapView().withAppRoutes()
            }
        case .log:
            NavigationStack(path: $router.logPath) {
                LogbookView().withAppRoutes()
            }
        case .vessel:
            NavigationStack(path: $router.vesselPath) {
                VesselView().withAppRoutes()
            }
        case .more:
            NavigationStack(path: $router.morePath) {
                MoreMenuView().withAppRoutes()
            }
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ route: SheetRoute) -> some View {
        switch route {
        case .quickActions:
            QuickActionsSheet()
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        case .addLogEvent:
            AddLogEventSheet()
        case .anchorWatch:
            AnchorWatchView()
        case .newVoyage:
            NewVoyageSheet()
                .presentationDetents([.medium])
        }
    }
}

/// Attaches the shared `navigationDestination` map so any tab can push the same
/// reference/detail screens.
private struct AppRoutesModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .vessel:       VesselView()
            case .crew:         CrewView()
            case .maintenance:  MaintenanceView()
            case .equipment:    EquipmentListView()
            case .serviceNotes: ServiceNotesView()
            case .seasonLog:    SeasonLogView()
            case .deviation:    DeviationView()
            case .statistics:   StatisticsView()
            case .weather:      WeatherView()
            case .settings:     SettingsView()
            case .voyageDetail(let box): VoyageDetailView(voyageID: box.id)
            }
        }
    }
}

extension View {
    func withAppRoutes() -> some View { modifier(AppRoutesModifier()) }
}
