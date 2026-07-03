import Foundation
import SwiftData

/// One GPS fix on a voyage's track. Kept lightweight — many per voyage.
@Model
final class TrackPoint {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speedMps: Double              // metres/second (negative if unknown → clamp on read)
    var courseDegrees: Double         // course over ground, 0..360 (−1 if unknown)
    /// How this segment was propelled, for the Statistics breakdown.
    var propulsionRaw: String

    var voyage: Voyage?

    init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        speedMps: Double,
        courseDegrees: Double,
        propulsion: PropulsionMode = .idle
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.speedMps = speedMps
        self.courseDegrees = courseDegrees
        self.propulsionRaw = propulsion.rawValue
    }

    var coordinate: GeoCoordinate {
        GeoCoordinate(latitude: latitude, longitude: longitude)
    }

    var speedKnots: Double { Units.mpsToKnots(speedMps) }

    var propulsion: PropulsionMode {
        get { PropulsionMode(rawValue: propulsionRaw) ?? .idle }
        set { propulsionRaw = newValue.rawValue }
    }
}
