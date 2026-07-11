import Foundation
import SwiftData
import Observation
import SwiftUI
import os

/// Man-Overboard controller. Saves the point the instant it is triggered, then
/// exposes live distance + bearing from the boat back to the person so the
/// active search screen can render the timer, range and homing compass arrow.
/// The engine owns the logbook trail — every trigger/resolve writes exactly one
/// entry, so all entry points (Today, Safety, Quick Actions, Map) behave
/// identically, including when there is no GPS fix.
@Observable
@MainActor
final class MOBEngine {

    private(set) var activePoint: MOBPoint?
    private(set) var distanceMeters: Double = 0
    private(set) var bearingDegrees: Double = 0     // from boat → MOB point

    private let context: ModelContext
    private let log = Logger(subsystem: "com.skipperlogbook.app", category: "MOBEngine")

    init(context: ModelContext) {
        self.context = context
        self.activePoint = Self.fetchActive(in: context)
    }

    var isActive: Bool { activePoint != nil }

    var elapsed: TimeInterval {
        guard let p = activePoint else { return 0 }
        return Date.now.timeIntervalSince(p.timestamp)
    }

    // MARK: Control

    /// Full MOB activation from a UI entry point: drops the marker at the
    /// current position when a fix exists; without one it still records the
    /// incident time in the logbook — the timestamp is the one thing a search
    /// can't do without. Haptic-confirms either way.
    ///
    /// Returns whether an MOB point is active afterwards — callers open the
    /// search screen only on `true`; on `false` they explain the missing fix
    /// instead of showing an empty search.
    @discardableResult
    func trigger(from location: LocationManager) -> Bool {
        if let coord = location.currentCoordinate {
            trigger(at: coord,
                    speedKn: Units.mpsToKnots(location.speedMps),
                    heading: location.effectiveHeading)
        } else {
            LogEvent.record(.mob, in: context,
                            note: String(localized: "mob.no_fix_note"))
            save()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        return isActive
    }

    /// Drop an MOB marker. If an incident is already active, it is kept as-is —
    /// the original position and time are what the search needs; no duplicate
    /// point or logbook entry is created.
    @discardableResult
    func trigger(at coordinate: GeoCoordinate,
                 speedKn: Double? = nil,
                 heading: Double? = nil) -> MOBPoint {
        if let existing = activePoint { return existing }
        let point = MOBPoint(timestamp: .now,
                             latitude: coordinate.latitude,
                             longitude: coordinate.longitude)
        context.insert(point)
        activePoint = point
        distanceMeters = 0
        bearingDegrees = 0
        LogEvent.record(.mob, in: context, at: coordinate,
                        heading: heading, speedKn: speedKn)
        save()
        return point
    }

    func resolve() {
        guard let p = activePoint else { return }
        p.resolved = true
        p.resolvedAt = .now
        activePoint = nil
        LogEvent.record(.mobResolved, in: context, at: p.coordinate)
        save()
    }

    // MARK: Ingest

    /// Update range & bearing from the boat's current position to the MOB point.
    func ingest(boat coordinate: GeoCoordinate) {
        guard let p = activePoint, coordinate.isValid else { return }
        distanceMeters = NavigationMath.haversineMeters(coordinate, p.coordinate)
        bearingDegrees = NavigationMath.initialBearingDegrees(from: coordinate, to: p.coordinate)
    }

    /// Relative bearing of the MOB point given the boat's heading — feeds the
    /// homing arrow (0 = dead ahead).
    func relativeBearing(boatHeading: Double) -> Double {
        NavigationMath.angularDifference(from: boatHeading, to: bearingDegrees)
    }

    private func save() {
        do {
            try context.save()
        } catch {
            log.error("MOB save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func fetchActive(in context: ModelContext) -> MOBPoint? {
        var descriptor = FetchDescriptor<MOBPoint>(
            predicate: #Predicate { $0.resolved == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
