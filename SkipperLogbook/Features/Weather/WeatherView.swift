import SwiftUI
import SwiftData

/// Fetches only the latest weather observations instead of materializing the
/// whole event table on every render.
private let weatherFetch: FetchDescriptor<LogEvent> = {
    let weatherRaw = LogEventType.weather.rawValue
    var descriptor = FetchDescriptor<LogEvent>(
        predicate: #Predicate { $0.typeRaw == weatherRaw },
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    descriptor.fetchLimit = 20
    return descriptor
}()

/// Weather — honest MVP: manual observations recorded into the logbook (wind,
/// free-text), listed here. Live forecast and tides are labeled Coming soon
/// until a real data source ships — nothing on this screen fakes live data.
struct WeatherView: View {
    @Environment(\.appTheme) private var theme

    @Query(weatherFetch, animation: .default) private var observations: [LogEvent]
    @State private var showLogWeather = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                manualCard

                SectionHeader("weather.recent")
                if observations.isEmpty {
                    EmptyStateView(symbol: "cloud.sun",
                                   title: "weather.empty_title",
                                   message: "weather.empty_message")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            ForEach(Array(observations.enumerated()), id: \.element.id) { i, event in
                                LogEventRow(event: event)
                                if i < observations.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                }

                SectionHeader("weather.planned")
                comingSoonCard("wind", "weather.forecast_title", "weather.forecast_message")
                comingSoonCard("water.waves", "weather.tides_title", "weather.tides_message")
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("weather.title")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showLogWeather) {
            AddLogEventSheet(initialType: .weather)
                .environment(\.appTheme, theme)
        }
    }

    private var manualCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "cloud.sun")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(theme.accentSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("weather.manual_title").font(AppFont.headline).foregroundStyle(theme.ink)
                        Text("weather.manual_message").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    }
                    Spacer(minLength: 0)
                }
                PrimaryButton(title: "weather.log_observation", symbol: "square.and.pencil", role: .accent) {
                    showLogWeather = true
                }
            }
        }
    }

    private func comingSoonCard(_ symbol: String, _ title: LocalizedStringKey,
                                _ message: LocalizedStringKey) -> some View {
        Card {
            HStack(spacing: Spacing.sm) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(theme.hairline))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.headline).foregroundStyle(theme.ink)
                    Text(message).font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                }
                Spacer(minLength: 0)
            }
        }
        .comingSoon()
    }
}

#Preview("Weather") {
    NavigationStack {
        WeatherView()
            .environment(\.appTheme, .light)
            .environment(LocationManager())
            .environment(VoyageRecorder(context: PreviewData.container.mainContext))
            .environment(AppState())
            .modelContainer(PreviewData.container)
    }
}
