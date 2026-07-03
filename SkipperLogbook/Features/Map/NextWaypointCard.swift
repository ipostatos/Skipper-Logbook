import SwiftUI

/// The floating "next waypoint" card on the map: name, distance, bearing and ETA
/// to the voyage destination, computed live from the current position.
struct NextWaypointCard: View {
    @Environment(\.appTheme) private var theme
    let voyage: Voyage
    let from: GeoCoordinate?
    let speedMps: Double

    private var distanceMeters: Double? {
        guard let dest = voyage.destination, let here = from else { return nil }
        return NavigationMath.haversineMeters(here, dest)
    }
    private var bearing: Double? {
        guard let dest = voyage.destination, let here = from else { return nil }
        return NavigationMath.initialBearingDegrees(from: here, to: dest)
    }
    private var etaSeconds: Double? {
        guard let d = distanceMeters else { return nil }
        return NavigationMath.etaSeconds(distanceMeters: d, speedMps: speedMps)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "location.north.line.fill").foregroundStyle(theme.accent)
                    Text(voyage.destinationName ?? String(localized: "map.next_waypoint"))
                        .font(AppFont.headline).foregroundStyle(theme.ink)
                    Spacer()
                    if let b = bearing {
                        Image(systemName: "location.north.fill")
                            .rotationEffect(.degrees(b))
                            .foregroundStyle(theme.warning)
                    }
                }
                HStack(spacing: Spacing.xl) {
                    metric(distanceMeters.map { "\(Units.metersToNM($0).oneDecimal) nm" } ?? "—", "map.distance")
                    metric(bearing.map { "\(Int($0))°" } ?? "—", "map.bearing")
                    metric(etaSeconds?.durationDHM ?? "—", "map.eta")
                }
            }
        }
    }

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink).monospacedDigit()
            Text(label).instrumentLabel(theme.inkSecondary)
        }
    }
}
