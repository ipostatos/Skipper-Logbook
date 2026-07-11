import SwiftUI
import SwiftData

/// The Today tab — a calm, contextual home. It surfaces the right primary card
/// by state: no voyage → Start CTA; recording → live navigation status; and it
/// always offers MOB, boat-state quick tiles, a stats grid and recent voyages.
/// Screen accent is blue (navigation).
struct TodayView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(MOBEngine.self) private var mob
    @Environment(AnchorWatchEngine.self) private var anchorWatch

    @Query private var vessels: [Vessel]
    @Query(sort: \Voyage.startedAt, order: .reverse) private var voyages: [Voyage]

    @State private var mobNoFix = false

    private var vessel: Vessel? { vessels.first }
    private var recent: [Voyage] { voyages.filter { !$0.isRecording }.prefix(3).map { $0 } }
    private var readout: DashboardReadout {
        DashboardReadout.make(location: location, recorder: recorder,
                              vesselFuelCapacity: vessel?.fuelCapacityLiters)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                header
                if mob.isActive { mobActiveBanner }
                if locationDenied { locationPermissionCard }
                if recorder.isRecording {
                    activeVoyageCard
                    courseCard
                    speedWaypointRow
                } else {
                    startCard
                }
                if anchorWatch.isActive { anchoredCard }
                mobCard
                StatusChipRow(engineOn: recorder.engineOn,
                              mainsailPercent: appState.mainsailPercent,
                              jibPercent: appState.jibPercent,
                              anchorDown: anchorWatch.isActive,
                              onEngine: toggleEngine, onSails: toggleSails,
                              onAnchor: { router.present(.anchorWatch) },
                              onNote: { router.present(.addLogEvent) })
                statsCard
                if !recent.isEmpty { recentSection }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .scrollIndicators(.hidden)
        .alert("mob.no_fix_title", isPresented: $mobNoFix) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("mob.no_fix_message") }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("today.title").font(AppFont.displayLarge).foregroundStyle(theme.ink)
                    BetaBadge()
                }
            }
            Spacer()
            Button { router.pushOnToday(.settings) } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.inkSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.surface))
                    .cardShadow(theme)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: Not recording — start CTA

    private var startCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("today.no_voyage").font(AppFont.headline).foregroundStyle(theme.ink)
                        Text("today.no_voyage_sub").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    }
                    Spacer()
                }
                PrimaryButton(title: "today.start_voyage", symbol: "record.circle", role: .accent) {
                    router.present(.newVoyage)
                }
            }
        }
    }

    // MARK: Recording — active voyage banner

    private var activeVoyageCard: some View {
        Card {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [theme.blue, theme.cyan],
                                                 startPoint: .top, endPoint: .bottom))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sailboat.fill").foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("today.active_voyage").instrumentLabel(theme.inkSecondary)
                    Text(recorder.activeVoyage?.name ?? "")
                        .font(AppFont.headline).foregroundStyle(theme.ink)
                    HStack(spacing: 6) {
                        Circle().fill(theme.green).frame(width: 7, height: 7)
                        Text("today.recording").font(AppFont.caption).foregroundStyle(theme.green)
                        Text(readout.timeUnderway.durationDHM)
                            .font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                    }
                }
                Spacer()
                Button { recorder.stopVoyage() } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30)).foregroundStyle(theme.danger)
                }.buttonStyle(.plain)
            }
        }
    }

    private var courseCard: some View {
        Card { CourseArc(course: readout.headingDegrees) }
    }

    private var speedWaypointRow: some View {
        // One track-tail slice feeds both cards (orderedTrack sorts on access).
        let tail = recorder.activeVoyage.map { Array($0.orderedTrack.suffix(20)) } ?? []
        return HStack(spacing: Spacing.sm) {
            metricSparkCard(SparkCardSpec(value: "\(readout.speedKn.oneDecimal)", unit: "kn",
                                          caption: "today.speed",
                                          symbol: "gauge.with.dots.needle.bottom.50percent",
                                          role: .blue),
                            samples: normalizedSpeeds(tail))
            metricSparkCard(SparkCardSpec(value: readout.remainingDistanceNM.map { $0.oneDecimal } ?? "—",
                                          unit: "nm", caption: "today.to_waypoint",
                                          symbol: "flag.fill", role: .purple),
                            samples: remainingSamples(tail))
        }
    }

    /// Everything static about a spark card — keeps the builder at two
    /// parameters (the lint limit is five).
    private struct SparkCardSpec {
        let value: String
        let unit: String
        let caption: LocalizedStringKey
        let symbol: String
        let role: AccentRole
    }

    private func metricSparkCard(_ spec: SparkCardSpec, samples: [CGFloat]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: spec.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.accent(spec.role))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(theme.accentSoft(spec.role)))
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(spec.value).font(AppFont.numeral(24)).foregroundStyle(theme.ink).monospacedDigit()
                            Text(spec.unit).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                        }
                        Text(spec.caption).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                    }
                    Spacer()
                }
                Sparkline(samples: samples, tint: theme.accent(spec.role))
                    .frame(height: 30)
            }
        }
    }

    // MARK: Smart-state cards

    private var locationDenied: Bool {
        location.permission == .denied || location.permission == .restricted
    }

    /// Location denied → live metrics can't work; explain and point to Settings.
    /// Manual logbook keeps working regardless.
    private var locationPermissionCard: some View {
        PermissionCard(symbol: "location.slash",
                       title: "permission.location_card_title",
                       message: "permission.location_card_message",
                       actionTitle: "permission.open_settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        }
    }

    /// An MOB is active → this beats everything else on the screen. Red is
    /// reserved for exactly this.
    private var mobActiveBanner: some View {
        Button { router.presentMOB() } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "figure.wave")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("today.mob_active").font(AppFont.headline).foregroundStyle(.white)
                    Text("today.mob_active_sub").font(AppFont.footnote).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.8))
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(theme.danger)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.mob_active_banner")
    }

    /// Anchor watch running → the dashboard's "anchored" state: distance vs.
    /// radius at a glance, red only if actually dragging.
    private var anchoredCard: some View {
        Button { router.present(.anchorWatch) } label: {
            Card {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "anchor.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(anchorWatch.isDragging ? theme.danger : theme.cyan)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill((anchorWatch.isDragging ? theme.danger : theme.cyan)
                            .opacity(theme.isDark ? 0.22 : 0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(anchorWatch.isDragging ? "today.anchor_dragging" : "today.anchored")
                            .font(AppFont.headline)
                            .foregroundStyle(anchorWatch.isDragging ? theme.danger : theme.ink)
                        Text("\(Int(anchorWatch.currentDistanceMeters)) m / \(Int(anchorWatch.session?.radiusMeters ?? 0)) m")
                            .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                            .monospacedDigit()
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(theme.inkTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: MOB card

    /// Hold-to-activate, like every MOB control in the app — an emergency
    /// trigger must not fire on an accidental tap.
    private var mobCard: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle().fill(theme.danger.opacity(0.15)).frame(width: 60, height: 60)
                Circle().fill(theme.danger).frame(width: 46, height: 46)
                Image(systemName: "figure.wave").foregroundStyle(.white).font(.system(size: 20, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("MOB").font(.system(size: 20, weight: .heavy)).foregroundStyle(theme.danger)
                Text("today.mob_hint").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(theme.danger.opacity(0.6))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .fill(theme.danger.opacity(0.08))
        )
        .contentShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        .onLongPressGesture(minimumDuration: MOBButton.holdDuration) { triggerMOB() }
        .accessibilityLabel(Text("mob.title"))
        .accessibilityHint(Text("safety.press_hold"))
    }

    // MARK: Stats grid

    private var statsCard: some View {
        Card {
            StatGrid(tiles: [
                .init(symbol: "point.topleft.down.to.point.bottomright.curvepath",
                      label: "dash.logged_distance", value: readout.loggedDistanceNM.oneDecimal, unit: "nm", tint: theme.blue),
                .init(symbol: "clock", label: "dash.time_underway",
                      value: readout.timeUnderway.durationDHM, tint: theme.cyan),
                .init(symbol: "clock.badge.checkmark", label: "dash.eta",
                      value: readout.etaSeconds?.durationDHM ?? "—", tint: theme.purple),
                .init(symbol: "fuelpump", label: "dash.fuel_remaining",
                      value: readout.fuelRemainingL.map { $0.oneDecimal } ?? "—", unit: "L", tint: theme.orange),
                .init(symbol: "water.waves", label: "dash.avg_speed",
                      value: readout.avgSpeedKn.oneDecimal, unit: "kn", tint: theme.blue),
                .init(symbol: "engine.combustion", label: "dash.engine_hours",
                      value: readout.engineHours.oneDecimal, unit: "h", tint: theme.orange)
            ], columns: 3)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader("dash.recent_voyages")
            Card(padding: Spacing.xxs) {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { i, voyage in
                        Button { router.pushOnToday(.voyageDetail(PersistentIDBox(id: voyage.persistentModelID))) } label: {
                            recentRow(voyage)
                        }.buttonStyle(.plain)
                        if i < recent.count - 1 { Divider().overlay(theme.hairline) }
                    }
                }
            }
        }
    }

    private func recentRow(_ voyage: Voyage) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sailboat").foregroundStyle(theme.blue).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(voyage.name).font(AppFont.subheadline).foregroundStyle(theme.ink)
                Text("\(voyage.startedAt.shortDate()) · \(voyage.distanceNM.oneDecimal) nm")
                    .font(AppFont.caption).foregroundStyle(theme.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(theme.inkTertiary)
        }
        .padding(.vertical, 8).padding(.horizontal, 6)
        .contentShape(Rectangle())
    }

    // MARK: Sparkline data (from the recent track tail, normalized)

    private func normalizedSpeeds(_ pts: [TrackPoint]) -> [CGFloat] {
        let speeds = pts.map { CGFloat($0.speedKnots) }
        guard let maxV = speeds.max(), maxV > 0 else { return [0.3, 0.5, 0.4, 0.6] }
        return speeds.map { $0 / maxV }
    }

    /// Real remaining-distance trend to the waypoint (previously this card was
    /// fed reversed *speed* samples — a meaningless line).
    private func remainingSamples(_ pts: [TrackPoint]) -> [CGFloat] {
        guard let dest = recorder.activeVoyage?.destination, !pts.isEmpty else { return [0.4, 0.4] }
        let dists = pts.map { CGFloat(NavigationMath.haversineMeters($0.coordinate, dest)) }
        guard let maxV = dists.max(), maxV > 0 else { return [0.4, 0.4] }
        return dists.map { $0 / maxV }
    }

    // MARK: Actions

    private func triggerMOB() {
        // The engine drops the marker, logs, and haptic-confirms — every MOB
        // path in the app behaves identically, with or without a GPS fix.
        if mob.trigger(from: location) {
            router.presentMOB()
        } else {
            mobNoFix = true   // time is logged; explain instead of an empty search
        }
    }

    private func toggleEngine() {
        recorder.toggleEngine(sailsUp: appState.mainsailPercent != nil)
    }

    private func toggleSails() {
        if appState.mainsailPercent == nil {
            appState.mainsailPercent = 100; appState.jibPercent = 100
            if recorder.isRecording {
                recorder.addEvent(.sailsUp, at: location.currentCoordinate, mainsailPercent: 100, jibPercent: 100)
            }
        } else {
            appState.mainsailPercent = nil; appState.jibPercent = nil
            if recorder.isRecording { recorder.addEvent(.sailsDown, at: location.currentCoordinate) }
        }
        recorder.setSailState(up: appState.mainsailPercent != nil)
    }
}

#Preview("Today") {
    @MainActor func host() -> some View {
        let container = PreviewData.container
        let context = container.mainContext
        return NavigationStack {
            TodayView()
                .environment(\.appTheme, .light)
                .environment(AppRouter())
                .environment(AppState())
                .environment(LocationManager())
                .environment(VoyageRecorder(context: context))
                .environment(MOBEngine(context: context))
                .environment(AnchorWatchEngine(context: context))
                .modelContainer(container)
        }
    }
    return host()
}
