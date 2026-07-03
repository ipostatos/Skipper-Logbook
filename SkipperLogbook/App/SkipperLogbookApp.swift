import SwiftUI
import SwiftData

@main
struct SkipperLogbookApp: App {

    /// The single on-disk container. Engines that need a context read its
    /// `mainContext`.
    private let container: ModelContainer

    @State private var appState = AppState()
    @State private var themeManager = ThemeManager()
    @State private var router = AppRouter()
    @State private var locationManager = LocationManager()
    @State private var permissions = PermissionsCenter()

    // Engines depend on the model context, so they're built after the container.
    @State private var recorder: VoyageRecorder
    @State private var anchorWatch: AnchorWatchEngine
    @State private var mob: MOBEngine
    @State private var liveActivity = LiveActivityController()

    init() {
        let container = PersistenceController.makeContainer()
        self.container = container

        let context = container.mainContext
        // Demo data never reaches a real user's store: first launch starts
        // empty. Seed only for development, via the `--seed-demo` launch
        // argument (previews and tests use their own in-memory containers).
        if ProcessInfo.processInfo.arguments.contains("--seed-demo") {
            SeedData.seedIfNeeded(context)
        }

        _recorder = State(initialValue: VoyageRecorder(context: context))
        _anchorWatch = State(initialValue: AnchorWatchEngine(context: context))
        _mob = State(initialValue: MOBEngine(context: context))
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
