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
    /// Latched after the alarm fires; resets once the boat is safely back inside
    /// (80% of the radius) so boundary jitter can't re-fire it continuously.
    private var alarmLatched = false
    /// nil until the user has answered the notification-permission prompt; the
    /// watch UI warns when this is false (the lock-screen half of the alarm is
    /// dead in that case).
    private(set) var alarmNotificationsAuthorized: Bool?

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
        alarmLatched = false
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
        alarmLatched = false
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
        if distance > s.maxDeviationMeters { s.maxDeviationMeters = distance }
        isDragging = distance > s.radiusMeters

        if isDragging, !alarmLatched {
            alarmLatched = true
            fireDragAlarm(at: coordinate, distance: distance)
        } else if distance < s.radiusMeters * 0.8 {
            alarmLatched = false
        }

        trail.append(coordinate)
        if trail.count > maxTrail { trail.removeFirst(trail.count - maxTrail) }
        save()
    }

    // MARK: Alarm

    /// An anchor watch that cannot wake the skipper is decoration: haptic thump,
    /// audible alert, local notification (for backgrounded/locked phones), and a
    /// logbook record of the excursion.
    private func fireDragAlarm(at coordinate: GeoCoordinate, distance: Double) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        postDragNotification(distance: distance)
        LogEvent.record(.anchorAlarm, in: context, at: coordinate,
                        note: String(localized: "anchor.drag_alarm_note"))
        log.warning("Anchor drag alarm at \(Int(distance)) m")
    }

    private func requestAlarmAuthorization() {
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
        let request = UNNotificationRequest(identifier: "anchor.drag",
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
