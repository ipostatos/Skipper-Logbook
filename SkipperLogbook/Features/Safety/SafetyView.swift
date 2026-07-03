import SwiftUI
import SwiftData

/// The Safety screen (Безопасность): a large press-and-hold MOB button, the last
/// MOB point with its distance + bearing, and an entry into the anchor watch.
struct SafetyView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Environment(LocationManager.self) private var location
    @Environment(MOBEngine.self) private var mob

    @Query(sort: \MOBPoint.timestamp, order: .reverse) private var mobPoints: [MOBPoint]

    @State private var mobNoFix = false

    private var lastMOB: MOBPoint? { mobPoints.first }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                MOBButton { triggerMOB() }
                    .padding(.top, Spacing.md)

                if let last = lastMOB {
                    lastMOBCard(last)
                }

                anchorEntry
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("safety.title")
        .navigationBarTitleDisplayMode(.large)
        .alert("mob.no_fix_title", isPresented: $mobNoFix) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("mob.no_fix_message") }
    }

    private func lastMOBCard(_ point: MOBPoint) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("safety.last_mob").instrumentLabel(theme.inkSecondary)
                Text("\(point.timestamp.shortDate()), \(point.timestamp.hourMinute())")
                    .font(AppFont.subheadline).foregroundStyle(theme.ink)
                Text(CoordinateFormatting.string(point.coordinate))
                    .font(AppFont.mono(.footnote)).foregroundStyle(theme.inkSecondary)

                Divider().overlay(theme.hairline)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("safety.distance_to_mob").instrumentLabel(theme.inkSecondary)
                        Text(distanceString(to: point)).font(AppFont.headingNumeral).foregroundStyle(theme.ink)
                    }
                    Spacer()
                    if let bearing = bearing(to: point) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(bearing))°").font(AppFont.statNumeral).foregroundStyle(theme.accent)
                            Image(systemName: "location.north.fill")
                                .rotationEffect(.degrees(bearing))
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
        }
    }

    private var anchorEntry: some View {
        Button { router.present(.anchorWatch) } label: {
            Card {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "anchor").font(.system(size: 22)).foregroundStyle(theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("anchor.title").font(AppFont.headline).foregroundStyle(theme.ink)
                        Text("anchor.entry_subtitle").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(theme.inkTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func triggerMOB() {
        if mob.trigger(from: location) {
            router.presentMOB()
        } else {
            mobNoFix = true
        }
    }

    private func distanceString(to point: MOBPoint) -> String {
        guard let here = location.currentCoordinate else { return "—" }
        let m = NavigationMath.haversineMeters(here, point.coordinate)
        return m < 1852 ? "\(Int(m)) m" : "\(Units.metersToNM(m).oneDecimal) nm"
    }

    private func bearing(to point: MOBPoint) -> Double? {
        guard let here = location.currentCoordinate else { return nil }
        return NavigationMath.initialBearingDegrees(from: here, to: point.coordinate)
    }
}

/// A large, pulsing press-and-hold MOB trigger. Requires a short hold to avoid
/// accidental fires; completes with a haptic thump.
struct MOBButton: View {
    @Environment(\.appTheme) private var theme
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isPressing = false
    /// One activation hold time for every MOB control in the app (the compact
    /// map button reuses it) — tune glove-friendliness in one place.
    static let holdDuration: TimeInterval = 0.7
    private var holdDuration: TimeInterval { Self.holdDuration }

    var body: some View {
        ZStack {
            // Pulsing halo
            Circle()
                .fill(theme.danger.opacity(0.15))
                .frame(width: 240, height: 240)
                .scaleEffect(isPressing ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPressing)
            Circle()
                .fill(theme.danger.opacity(0.25))
                .frame(width: 190, height: 190)
            // Progress ring while holding
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.background, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 168, height: 168)
            Circle()
                .fill(theme.danger)
                .frame(width: 160, height: 160)
            VStack(spacing: 2) {
                Text("MOB").font(.system(size: 32, weight: .heavy)).foregroundStyle(.white)
                Text("safety.press_hold").font(AppFont.caption).foregroundStyle(.white.opacity(0.9))
            }
        }
        .contentShape(Circle())
        .gesture(
            LongPressGesture(minimumDuration: holdDuration)
                .onChanged { _ in beginHold() }
                .onEnded { _ in complete() }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in cancelHold() }
        )
        .onAppear { isPressing = true }
        .accessibilityLabel("Man overboard")
        .accessibilityHint(Text("safety.press_hold"))
    }

    private func beginHold() {
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }
    }
    private func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        progress = 0
        action()
    }
    private func cancelHold() {
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
    }
}

#Preview("Safety") {
    NavigationStack {
        SafetyView()
            .environment(\.appTheme, .paper)
            .environment(AppRouter())
            .environment(LocationManager())
            .environment(MOBEngine(context: PreviewData.container.mainContext))
            .modelContainer(PreviewData.container)
    }
}
