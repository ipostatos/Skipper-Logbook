import SwiftUI

/// First-run onboarding: introduces the app, primes the location permission,
/// then hands off to the main shell. Kept short and calm to match the mono style.
struct OnboardingView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var location

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            SailboatMark()
                .frame(width: 96, height: 96)

            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Text("Skipper Logbook")
                        .font(AppFont.display(30))
                        .foregroundStyle(theme.ink)
                    BetaBadge()
                }
                Text("onboarding.tagline")
                    .font(AppFont.subheadline)
                    .foregroundStyle(theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                feature("record.circle", "onboarding.feature_track")
                feature("list.bullet.rectangle", "onboarding.feature_log")
                feature("exclamationmark.triangle", "onboarding.feature_safety")
            }
            .padding(.horizontal, Spacing.md)

            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButton(title: "onboarding.enable_location", symbol: "location.fill") {
                    location.requestWhenInUse()
                }
                Button("onboarding.get_started") {
                    appState.hasCompletedOnboarding = true
                }
                .font(AppFont.headline)
                .foregroundStyle(theme.accent)
                .accessibilityIdentifier("onboarding.get_started")

                Text("settings.disclaimer")
                    .font(AppFont.caption)
                    .foregroundStyle(theme.inkTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .onChange(of: location.permission) { _, newValue in
            // Once the user answers the location prompt, move on automatically.
            if newValue != .notDetermined {
                appState.hasCompletedOnboarding = true
            }
        }
    }

    private func feature(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 28)
            Text(text)
                .font(AppFont.subheadline)
                .foregroundStyle(theme.ink)
            Spacer()
        }
    }
}

#Preview("Onboarding") {
    OnboardingView()
        .environment(\.appTheme, .paper)
        .environment(AppState())
        .environment(LocationManager())
}
