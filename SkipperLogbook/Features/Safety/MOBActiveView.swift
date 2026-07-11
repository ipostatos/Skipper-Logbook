import SwiftUI

/// The full-screen active Man-Overboard search. Shows the time since the MOB was
/// triggered, the range and accuracy, the bearing back to the point, and a
/// homing compass whose arrow points toward the person relative to the boat's
/// heading. Matches the dark MOB search mockup.
struct MOBActiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var location
    @Environment(MOBEngine.self) private var mob

    // The MOB screen is always presented in the night palette for legibility.
    private let theme = AppTheme.night

    @State private var now: Date = .now
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                topBar
                Spacer(minLength: 0)
                readouts
                homingCompass
                position
                Spacer(minLength: 0)
                resolveButton
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.lg)
        }
        .environment(\.appTheme, theme)
        .onReceive(ticker) { now = $0 }
        .onAppear {
            if let coord = location.currentCoordinate { mob.ingest(boat: coord) }
        }
    }

    private var topBar: some View {
        HStack {
            Label("mob.title", systemImage: "exclamationmark.triangle.fill")
                .font(AppFont.headline).foregroundStyle(theme.danger)
            Spacer()
            Button("mob.exit") { dismiss() }
                .font(AppFont.subheadline.weight(.semibold))
                .foregroundStyle(theme.ink)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().strokeBorder(theme.hairline, lineWidth: 1))
        }
    }

    private var readouts: some View {
        VStack(spacing: Spacing.xs) {
            Text(mob.elapsed.stopwatchMMSS)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.ink).monospacedDigit()
            Text("\(Int(mob.distanceMeters)) m")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(theme.ink).monospacedDigit()
            Text(String(format: String(localized: "mob.accuracy"), Int(accuracy)))
                .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
            // "°T": the bearing is TRUE (computed from coordinates) — flag it so
            // nobody steers it on a magnetic compass card.
            Text("\(Int(mob.bearingDegrees))°T")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accent).monospacedDigit()
        }
    }

    /// A compass ring with a bold arrow pointing at the person, rotated by the
    /// relative bearing (MOB bearing − boat heading).
    private var homingCompass: some View {
        // The MOB bearing is true (from coordinates); mixing in a magnetic
        // effectiveHeading would skew the arrow by the local declination.
        let relative = mob.relativeBearing(boatHeading: location.trueReferenceHeading)
        return ZStack {
            CompassDial(heading: location.trueReferenceHeading, showNumeral: false)
                .frame(width: 240, height: 240)
            Image(systemName: "location.north.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(theme.accent)
                .offset(y: -70)
                .rotationEffect(.degrees(relative))
        }
        .frame(height: 260)
    }

    private var position: some View {
        Group {
            if let point = mob.activePoint {
                Text(CoordinateFormatting.string(point.coordinate))
                    .font(AppFont.mono(.footnote)).foregroundStyle(theme.inkSecondary)
            }
        }
    }

    private var resolveButton: some View {
        PrimaryButton(title: "mob.resolved", symbol: "checkmark.circle", role: .accent) {
            mob.resolve()
            dismiss()
        }
    }

    private var accuracy: Double {
        location.currentLocation?.horizontalAccuracy ?? 5
    }
}

#Preview("MOB active") {
    MOBActiveView()
        .environment(LocationManager())
        .environment({
            let e = MOBEngine(context: PreviewData.container.mainContext)
            e.trigger(at: GeoCoordinate(latitude: 43.288, longitude: 5.343))
            return e
        }())
        .modelContainer(PreviewData.container)
}
