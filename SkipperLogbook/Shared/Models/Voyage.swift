import Foundation
import SwiftData

/// A single passage / trip. Owns the GPS track, the log entries and voice notes
/// recorded during it. `isRecording` marks the one currently-active voyage.
@Model
final class Voyage {
    var name: String                 // "Балтика 2025", "Выход в море"
    var startedAt: Date
    var endedAt: Date?
    var isRecording: Bool

    /// Accumulated great-circle distance in metres (integrated as points arrive).
    var distanceMeters: Double
    /// Seconds the engine was running during this voyage.
    var engineSeconds: Double
    /// Litres of fuel burned (estimated or logged).
    var fuelUsedLiters: Double

    // Optional destination / next waypoint for ETA & "to waypoint" readouts.
    var destinationName: String?
    var destinationLat: Double?
    var destinationLon: Double?
    /// Planned total route distance (metres) if known, for "remaining distance".
    var plannedDistanceMeters: Double?

    @Relationship(deleteRule: .cascade, inverse: \TrackPoint.voyage)
    var trackPoints: [TrackPoint]

    @Relationship(deleteRule: .cascade, inverse: \LogEvent.voyage)
    var events: [LogEvent]

    @Relationship(deleteRule: .cascade, inverse: \VoiceNote.voyage)
    var voiceNotes: [VoiceNote]

    init(
        name: String,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        isRecording: Bool = false,
        distanceMeters: Double = 0,
        engineSeconds: Double = 0,
        fuelUsedLiters: Double = 0,
        destinationName: String? = nil,
        destinationLat: Double? = nil,
        destinationLon: Double? = nil,
        plannedDistanceMeters: Double? = nil
    ) {
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isRecording = isRecording
        self.distanceMeters = distanceMeters
        self.engineSeconds = engineSeconds
        self.fuelUsedLiters = fuelUsedLiters
        self.destinationName = destinationName
        self.destinationLat = destinationLat
        self.destinationLon = destinationLon
        self.plannedDistanceMeters = plannedDistanceMeters
        self.trackPoints = []
        self.events = []
        self.voiceNotes = []
    }

    // MARK: Derived

    var distanceNM: Double { Units.metersToNM(distanceMeters) }

    var elapsed: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var engineHours: Double { engineSeconds / 3_600 }

    /// Average speed in knots over the elapsed time (0 if no time yet).
    var averageSpeedKn: Double {
        let hours = elapsed / 3_600
        guard hours > 0 else { return 0 }
        return distanceNM / hours
    }

    var destination: GeoCoordinate? {
        guard let lat = destinationLat, let lon = destinationLon else { return nil }
        return GeoCoordinate(latitude: lat, longitude: lon)
    }

    /// Track points in chronological order — the source for the map polyline.
    var orderedTrack: [TrackPoint] {
        trackPoints.sorted { $0.timestamp < $1.timestamp }
    }

    var orderedEvents: [LogEvent] {
        events.sorted { $0.timestamp > $1.timestamp }
    }
}

extension Voyage {
    /// The voyage currently being recorded, if any. Shared by the safety engines
    /// so the logbook events they write attach to the right trip.
    static func recording(in context: ModelContext) -> Voyage? {
        var descriptor = FetchDescriptor<Voyage>(
            predicate: #Predicate { $0.isRecording == true },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
