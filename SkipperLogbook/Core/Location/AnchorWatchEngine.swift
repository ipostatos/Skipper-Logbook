import Foundation
import SwiftData
import CoreLocation
import Observation

/// Runs an anchor watch: the captain drops anchor at the current position, sets
/// an alarm radius, and the engine tracks distance-from-anchor, max deviation,
/// and whether the boat has dragged outside the circle.
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
        save()
    }

    func stop() {
        guard let s = session, s.isActive else { return }
        s.isActive = false
        s.endedAt = .now
        session = nil
        trail = []
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

        trail.append(coordinate)
        if trail.count > maxTrail { trail.removeFirst(trail.count - maxTrail) }
        save()
    }

    private func save() {
        do { try context.save() } catch { }
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
