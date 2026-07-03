import Foundation
import SwiftData

/// A Man-Overboard marker. Saved the instant the MOB button fires; the active
/// search screen then reads distance/bearing from the boat back to this point.
@Model
final class MOBPoint {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var resolved: Bool                // captain marked the situation resolved
    var resolvedAt: Date?

    init(
        timestamp: Date = .now,
        latitude: Double,
        longitude: Double,
        resolved: Bool = false,
        resolvedAt: Date? = nil
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.resolved = resolved
        self.resolvedAt = resolvedAt
    }

    var coordinate: GeoCoordinate {
        GeoCoordinate(latitude: latitude, longitude: longitude)
    }
}
