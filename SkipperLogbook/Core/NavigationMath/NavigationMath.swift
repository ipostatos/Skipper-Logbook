import Foundation

/// Pure great-circle / rhumb navigation math over `GeoCoordinate`. No
/// CoreLocation, no side effects — every function is deterministic and unit-tested.
enum NavigationMath {

    /// Mean Earth radius in metres.
    static let earthRadius = 6_371_000.0

    // MARK: Angle helpers

    static func degreesToRadians(_ d: Double) -> Double { d * .pi / 180 }
    static func radiansToDegrees(_ r: Double) -> Double { r * 180 / .pi }

    /// Wraps any angle into the [0, 360) range.
    static func normalizedDegrees(_ degrees: Double) -> Double {
        let m = degrees.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }

    /// Smallest signed difference `to − from` in degrees, within [−180, 180].
    /// Positive means `to` is clockwise from `from`.
    static func angularDifference(from: Double, to: Double) -> Double {
        var diff = normalizedDegrees(to) - normalizedDegrees(from)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }

    // MARK: Distance & bearing

    /// Great-circle distance between two coordinates, in metres (haversine).
    static func haversineMeters(_ a: GeoCoordinate, _ b: GeoCoordinate) -> Double {
        let lat1 = degreesToRadians(a.latitude)
        let lat2 = degreesToRadians(b.latitude)
        let dLat = degreesToRadians(b.latitude - a.latitude)
        let dLon = degreesToRadians(b.longitude - a.longitude)

        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(h), sqrt(1 - h))
        return earthRadius * c
    }

    /// Initial great-circle bearing from `a` to `b`, in degrees [0, 360).
    static func initialBearingDegrees(from a: GeoCoordinate, to b: GeoCoordinate) -> Double {
        let lat1 = degreesToRadians(a.latitude)
        let lat2 = degreesToRadians(b.latitude)
        let dLon = degreesToRadians(b.longitude - a.longitude)

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return normalizedDegrees(radiansToDegrees(atan2(y, x)))
    }

    /// Signed cross-track distance (metres) of `point` from the great-circle
    /// path start→end. Positive = right of track, negative = left.
    static func crossTrackMeters(point p: GeoCoordinate,
                                 start: GeoCoordinate,
                                 end: GeoCoordinate) -> Double {
        let d13 = haversineMeters(start, p) / earthRadius        // angular dist start→point
        let theta13 = degreesToRadians(initialBearingDegrees(from: start, to: p))
        let theta12 = degreesToRadians(initialBearingDegrees(from: start, to: end))
        return asin(sin(d13) * sin(theta13 - theta12)) * earthRadius
    }

    // MARK: Totals

    /// Total great-circle length of a track (metres), summing consecutive legs.
    static func trackLengthMeters(_ points: [GeoCoordinate]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<points.count {
            total += haversineMeters(points[i - 1], points[i])
        }
        return total
    }

    // MARK: ETA

    /// Seconds to cover `distanceMeters` at `speedMps`. `nil` when not moving.
    static func etaSeconds(distanceMeters: Double, speedMps: Double) -> Double? {
        guard speedMps > 0.01 else { return nil }
        return distanceMeters / speedMps
    }

    /// Convenience: ETA in seconds using knots.
    static func etaSeconds(distanceNM: Double, speedKn: Double) -> Double? {
        guard speedKn > 0.01 else { return nil }
        return (distanceNM / speedKn) * 3_600
    }

    /// Offsets a coordinate by `distanceMeters` along `bearingDegrees`.
    /// Used to synthesise test/seed tracks and to place the anchor circle.
    static func destination(from origin: GeoCoordinate,
                            bearingDegrees: Double,
                            distanceMeters: Double) -> GeoCoordinate {
        let angular = distanceMeters / earthRadius
        let bearing = degreesToRadians(bearingDegrees)
        let lat1 = degreesToRadians(origin.latitude)
        let lon1 = degreesToRadians(origin.longitude)

        let lat2 = asin(sin(lat1) * cos(angular) + cos(lat1) * sin(angular) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(angular) * cos(lat1),
                                cos(angular) - sin(lat1) * sin(lat2))
        return GeoCoordinate(latitude: radiansToDegrees(lat2),
                             longitude: radiansToDegrees(lon2))
    }
}
