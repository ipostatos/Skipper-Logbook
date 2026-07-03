import Foundation
import SwiftData

/// A record of an anchor-watch session: where the anchor was dropped, the alarm
/// radius, and the max drift observed. The live watch itself runs in
/// `AnchorWatchEngine`; this persists the history / current state.
@Model
final class AnchorWatchSession {
    var startedAt: Date
    var endedAt: Date?

    var anchorLat: Double
    var anchorLon: Double
    var radiusMeters: Double          // alarm radius (e.g. 15 m)

    var maxDeviationMeters: Double    // furthest the boat drifted from the anchor
    var isActive: Bool

    init(
        startedAt: Date = .now,
        endedAt: Date? = nil,
        anchorLat: Double,
        anchorLon: Double,
        radiusMeters: Double,
        maxDeviationMeters: Double = 0,
        isActive: Bool = true
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.anchorLat = anchorLat
        self.anchorLon = anchorLon
        self.radiusMeters = radiusMeters
        self.maxDeviationMeters = maxDeviationMeters
        self.isActive = isActive
    }

    var anchor: GeoCoordinate {
        GeoCoordinate(latitude: anchorLat, longitude: anchorLon)
    }
}
