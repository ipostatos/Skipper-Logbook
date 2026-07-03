import Foundation
import SwiftData
import Observation

/// Man-Overboard controller. Saves the point the instant it is triggered, then
/// exposes live distance + bearing from the boat back to the person so the
/// active search screen can render the timer, range and homing compass arrow.
@Observable
@MainActor
final class MOBEngine {

    private(set) var activePoint: MOBPoint?
    private(set) var distanceMeters: Double = 0
    private(set) var bearingDegrees: Double = 0     // from boat → MOB point

    private let context: ModelContext

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

    /// Drop an MOB marker at the current position. Returns the new point.
    @discardableResult
    func trigger(at coordinate: GeoCoordinate) -> MOBPoint {
        let point = MOBPoint(timestamp: .now,
                             latitude: coordinate.latitude,
                             longitude: coordinate.longitude)
        context.insert(point)
        activePoint = point
        distanceMeters = 0
        bearingDegrees = 0
        save()
        return point
    }

    func resolve() {
        guard let p = activePoint else { return }
        p.resolved = true
        p.resolvedAt = .now
        activePoint = nil
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
        do { try context.save() } catch { }
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
