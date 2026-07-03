import CoreLocation

/// A plain latitude/longitude pair, deliberately free of CoreLocation so the
/// navigation math is pure and unit-testable. Bridges to `CLLocationCoordinate2D`.
struct GeoCoordinate: Equatable, Hashable, Codable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ clCoordinate: CLLocationCoordinate2D) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// True when both components are valid finite numbers (0,0 excluded — it's
    /// almost always an uninitialised value at sea).
    var isValid: Bool {
        latitude.isFinite && longitude.isFinite
            && abs(latitude) <= 90 && abs(longitude) <= 180
            && !(latitude == 0 && longitude == 0)
    }
}

extension CLLocationCoordinate2D {
    var geo: GeoCoordinate { GeoCoordinate(self) }
}
