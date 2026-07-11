import Foundation
import SwiftData
import CoreLocation
import Observation
import SwiftUI
import AudioToolbox
import UserNotifications
import os

/// Runs an anchor watch: the captain drops anchor at the current position, sets
/// an alarm radius, and the engine tracks distance-from-anchor, max deviation,
/// and whether the boat has dragged outside the circle. Dragging fires a real
/// alarm (haptic + alert sound + local notification) and every start/stop/drag
/// is written to the logbook.
@Observable
@MainActor
final class AnchorWatchEngine {

    private(set) var session: AnchorWatchSession?
    private(set) var currentDistanceMeters: Double = 0
    private(set) var isDragging = false
    /// Recent boat positions relative to the anchor, for the drift-circle trail.
    private(set) var trail: [GeoCoordinate] = []

    private let context: ModelContext
    private let maxTrail = 200
    private let log = Logger(subsystem: "com.skipperlogbook.app", category: "AnchorWatch")
    /// One "excursion" = one trip outside the circle. The logbook records it
    /// once, but the audible alarm REPEATS every `alarmRepeatInterval` while
    /// the boat stays outside — a single beep does not wake a sleeping skipper.
    /// The excursion clears once the boat is safely back inside (80% of the
    /// radius) so boundary jitter can't re-trigger it continuously.
    private var excursionActive = false
    private var lastAlarmAt = Date.distantPast
    private let alarmRepeatInterval: TimeInterval = 20
    /// Session writes are throttled: state changes and deviation growth persist
    /// immediately, otherwise at most every 30 s (an all-night watch must not
    /// hit the disk on every fix).
    private var lastPersistAt = Date.distantPast
    /// nil until the user has answered the notification-permission prompt; the
    /// watch UI warns when this is false (the lock-screen half of the alarm is
    /// dead in that case).
    private(set) var alarmNotificationsAuthorized: Bool?
    /// System sound / notification-center calls hang headless CI simulators;
    /// unit tests assert the logbook + latch logic, not the beep.
    private static let isRunningTests =
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init(context: ModelContext) {
        self.context = context
        self.session = Self.fetchActive(in: context)
    }

    var isActive: Bool { session?.isActive ?? false }

    var elapsed: TimeInterval {
        guard let s = session else { return 0 }
        return (s.endedAt ?? .now).timeIntervalSince(s.startedAt)
    }

    // MARK: Control

    func start(at anchor: GeoCoordinate, radiusMeters: Double) {
        stop() // close any prior
        let s = AnchorWatchSession(anchorLat: anchor.latitude,
                                   anchorLon: anchor.longitude,
                                   radiusMeters: radiusMeters)
        context.insert(s)
        session = s
        trail = [anchor]
        currentDistanceMeters = 0
        isDragging = false
        excursionActive = false
        lastAlarmAt = .distantPast
        LogEvent.record(.anchorDown, in: context, at: anchor)
        save()
        requestAlarmAuthorization()
    }

    func stop() {
        guard let s = session, s.isActive else { return }
        s.isActive = false
        s.endedAt = .now
        session = nil
        trail = []
        isDragging = false
        excursionActive = false
        LogEvent.record(.anchorUp, in: context, at: s.anchor)
        save()
    }

    func updateRadius(_ meters: Double) {
        session?.radiusMeters = max(5, meters)
        save()
    }

    // MARK: Ingest

    func ingest(_ coordinate: GeoCoordinate) {
        guard let s = session, s.isActive, coordinate.isValid else { return }
        let distance = NavigationMath.haversineMeters(s.anchor, coordinate)
        currentDistanceMeters = distance
        var deviationGrew = false
        if distance > s.maxDeviationMeters + 0.5 {
            s.maxDeviationMeters = distance
            deviationGrew = true
        }
        let wasDragging = isDragging
        isDragging = distance > s.radiusMeters

        if isDragging {
            if !excursionActive {
                excursionActive = true
                fireDragAlarm(at: coordinate, distance: distance, logEntry: true)
            } else if Date.now.timeIntervalSince(lastAlarmAt) >= alarmRepeatInterval {
                // Still dragging: keep sounding, but don't spam the logbook —
                // one excursion is one logbook line.
                fireDragAlarm(at: coordinate, distance: distance, logEntry: false)
            }
        } else if excursionActive, distance < s.radiusMeters * 0.8 {
            excursionActive = false
            postAllClearNotification()
        }

        trail.append(coordinate)
        if trail.count > maxTrail { trail.removeFirst(trail.count - maxTrail) }

        if wasDragging != isDragging || deviationGrew
            || Date.now.timeIntervalSince(lastPersistAt) >= 30 {
            lastPersistAt = .now
            save()
        }
    }

    // MARK: Alarm

    /// An anchor watch that cannot wake the skipper is decoration: haptic thump,
    /// audible alert, time-sensitive local notification (for backgrounded/locked
    /// phones), and — once per excursion — a logbook record.
    private func fireDragAlarm(at coordinate: GeoCoordinate, distance: Double, logEntry: Bool) {
        lastAlarmAt = .now
        if !Self.isRunningTests {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            AudioServicesPlayAlertSound(SystemSoundID(1005))
            postDragNotification(distance: distance)
        }
        if logEntry {
            LogEvent.record(.anchorAlarm, in: context, at: coordinate,
                            note: String(localized: "anchor.drag_alarm_note"))
            log.warning("Anchor drag alarm at \(Int(distance)) m")
        }
    }

    private func requestAlarmAuthorization() {
        guard !Self.isRunningTests else { return }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                Task { @MainActor in
                    self.alarmNotificationsAuthorized = granted
                }
            }
    }

    private func postDragNotification(distance: Double) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "anchor.alarm_title")
        // Explicit format lookup — unambiguous against the catalog key.
        content.body = String(format: String(localized: "anchor.alarm_body"), Int(distance))
        content.sound = .default
        // Break through Focus / silenced delivery — this is exactly what the
        // Time Sensitive level exists for (entitlement added to the app target).
        content.interruptionLevel = .timeSensitive
        // Unique id per repeat: replacing a still-delivered "anchor.drag" would
        // update it silently instead of alerting again.
        let request = UNNotificationRequest(identifier: "anchor.drag.\(UUID().uuidString)",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    /// Gentle follow-up so a skipper woken by the drag alarm knows the boat is
    /// back inside the circle (re-anchored / swing corrected).
    private func postAllClearNotification() {
        guard !Self.isRunningTests else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "anchor.all_clear_title")
        content.body = String(localized: "anchor.all_clear_body")
        content.sound = .default
        let request = UNNotificationRequest(identifier: "anchor.allclear",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func save() {
        do { try context.save() }
        catch { log.error("Anchor watch save failed: \(error.localizedDescription, privacy: .public)") }
    }

    private static func fetchActive(in context: ModelContext) -> AnchorWatchSession? {
        var descriptor = FetchDescriptor<AnchorWatchSession>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
