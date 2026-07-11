import SwiftUI
import SwiftData

/// The root tab shell. Hosts one `NavigationStack` per tab, the custom bottom
/// bar with a floating +, the quick-actions sheet, and the full-screen MOB
/// cover. Location fan-out to the engines lives in `FixCoordinator` (NOT here):
/// safety-critical ingestion must not depend on a SwiftUI scene being alive.
struct RootView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Environment(LocationManager.self) private var location
    @Environment(AnchorWatchEngine.self) private var anchorWatch
    @Environment(MOBEngine.self) private var mob

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
        .onAppear { location.start(); updateSafetyOverride() }
        // The coordinator enforces this on every fix too; these hooks apply it
        // the instant a watch starts/stops, before the next fix arrives.
        .onChange(of: anchorWatch.isActive) { _, _ in updateSafetyOverride() }
        .onChange(of: mob.isActive) { _, _ in updateSafetyOverride() }
    }

    /// While a safety engine runs, keep location flowing in the background so
    /// the anchor alarm / MOB range stay live with the phone locked.
    private func updateSafetyOverride() {
        location.safetyBackgroundOverride = anchorWatch.isActive || mob.isActive
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
            case .safety:       SafetyView()
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
