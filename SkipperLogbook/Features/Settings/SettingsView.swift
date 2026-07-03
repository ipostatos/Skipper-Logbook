import SwiftUI

/// Settings: appearance (day/night/system), units, background tracking toggle,
/// permissions status, and about/BETA info. Sync/export are Coming soon.
struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var location

    var body: some View {
        @Bindable var appState = appState
        @Bindable var location = location

        Form {
            Section("settings.appearance") {
                Picker("settings.theme", selection: Binding(
                    get: { themeManager.mode },
                    set: { themeManager.select($0) })) {
                    ForEach(ThemeMode.allCases) { mode in
                        Label(mode.titleKey, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("settings.units") {
                // Displays are nautical-only for now; a working switch ships
                // with the unit formatter pass. Until then: honest Coming soon.
                Picker("settings.unit_system", selection: $appState.unitSystem) {
                    ForEach(UnitSystem.allCases) { u in
                        Text(LocalizedStringKey(u.titleKey)).tag(u)
                    }
                }
                .comingSoon()
            }

            Section("settings.tracking") {
                Toggle("settings.background_tracking", isOn: $location.allowsBackground)
                Text("settings.background_hint")
                    .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                if location.backgroundUpgradeNeeded {
                    Text("settings.background_needs_always")
                        .font(AppFont.footnote).foregroundStyle(theme.warning)
                }
                LabeledContent("settings.location_permission") {
                    Text(location.permission.titleKey).foregroundStyle(theme.inkSecondary)
                }
                if !location.permission.isAuthorized {
                    Button("settings.grant_location") { location.requestWhenInUse() }
                }
            }

            Section("settings.data") {
                Button {} label: { Label("settings.export_pdf", systemImage: "doc.richtext") }
                    .comingSoon()
                Button {} label: { Label("settings.icloud_sync", systemImage: "icloud") }
                    .comingSoon()
            }

            Section("settings.about") {
                LabeledContent("settings.version") {
                    HStack(spacing: 6) {
                        Text(appVersion).foregroundStyle(theme.inkSecondary)
                        BetaBadge()
                    }
                }
                Text("settings.disclaimer")
                    .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
            }
        }
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.large)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.9.0"
        return "v\(v)"
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environment(\.appTheme, .paper)
            .environment(ThemeManager())
            .environment(AppState())
            .environment(LocationManager())
    }
}
