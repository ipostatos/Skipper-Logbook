import SwiftUI
import SwiftData

@main
struct SkipperLogbookApp: App {

    /// The single on-disk container. Engines that need a context read its
    /// `mainContext`.
    private let container: ModelContainer

    @State private var appState: AppState
    @State private var themeManager: ThemeManager
    @State private var router: AppRouter
    @State private var locationManager: LocationManager
    @State private var permissions: PermissionsCenter

    // Engines depend on the model context, so they're built after the container.
    @State private var recorder: VoyageRecorder
    @State private var anchorWatch: AnchorWatchEngine
    @State private var mob: MOBEngine
    @State private var liveActivity: LiveActivityController
    /// Owns the fix fan-out (engines + widgets) outside the view layer — the
    /// safety chain must not depend on a SwiftUI scene being alive.
    @State private var fixCoordinator: FixCoordinator

    init() {
        let container = PersistenceController.makeContainer()
        self.container = container

        let context = container.mainContext
        // Demo data never reaches a real user's store: first launch starts
        // empty. Seed only for development, via the `--seed-demo` launch
        // argument (previews and tests use their own in-memory containers).
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--seed-demo") {
            SeedData.seedIfNeeded(context)
        }
        // UI-test / preview hook: seed an *unresolved* MOB so the emergency
        // search screen renders deterministically in CI (no live GPS fix needed).
        if args.contains("--seed-mob-active") {
            SeedData.seedActiveMOB(context)
        }

        // Swift 5.10 evaluates stored-property default values in a nonisolated
        // context, so the @MainActor singletons must be built here, inside the
        // App's @MainActor init.
        _appState = State(initialValue: AppState())
        _themeManager = State(initialValue: ThemeManager())
        _router = State(initialValue: AppRouter())
        let location = LocationManager()
        _locationManager = State(initialValue: location)
        _permissions = State(initialValue: PermissionsCenter())
        let recorder = VoyageRecorder(context: context)
        let anchorWatch = AnchorWatchEngine(context: context)
        let mob = MOBEngine(context: context)
        let liveActivity = LiveActivityController()
        _recorder = State(initialValue: recorder)
        _anchorWatch = State(initialValue: anchorWatch)
        _mob = State(initialValue: mob)
        _liveActivity = State(initialValue: liveActivity)

        // Fan-out lives outside the view layer: as long as the process runs and
        // CoreLocation delivers, the recorder and safety engines get every fix.
        let coordinator = FixCoordinator(location: location, recorder: recorder,
                                         anchorWatch: anchorWatch, mob: mob,
                                         liveActivity: liveActivity, context: context)
        _fixCoordinator = State(initialValue: coordinator)
        coordinator.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environment(appState)
                .environment(themeManager)
                .environment(router)
                .environment(locationManager)
                .environment(permissions)
                .environment(recorder)
                .environment(anchorWatch)
                .environment(mob)
                .environment(liveActivity)
                .modelContainer(container)
        }
    }
}

/// Resolves the active theme against the system color scheme and injects it into
/// the environment, then shows onboarding or the root tab shell.
private struct RootContainerView: View {
    @Environment(\.colorScheme) private var systemScheme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState

    var body: some View {
        let theme = themeManager.theme(for: systemScheme)
        Group {
            if appState.hasCompletedOnboarding {
                RootView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.appTheme, theme)
        .tint(theme.accent)
        .preferredColorScheme(themeManager.mode.preferredColorScheme)
    }
}
