import Foundation

/// Formats coordinates the way navigators read them. Supports the two forms
/// seen in the mockups: DMS (`N43°17'16" E005°20'33"`) and degrees-decimal-
/// minutes (`N 59°57.420' E 030°18.640'`).
enum CoordinateFormatting {

    enum Style { case dms, ddm }

    static func string(_ coordinate: GeoCoordinate, style: Style = .ddm) -> String {
        let lat = component(coordinate.latitude, isLatitude: true, style: style)
        let lon = component(coordinate.longitude, isLatitude: false, style: style)
        return "\(lat)  \(lon)"
    }

    static func latitudeString(_ latitude: Double, style: Style = .ddm) -> String {
        component(latitude, isLatitude: true, style: style)
    }

    static func longitudeString(_ longitude: Double, style: Style = .ddm) -> String {
        component(longitude, isLatitude: false, style: style)
    }

    // MARK: - Private

    private static func component(_ value: Double, isLatitude: Bool, style: Style) -> String {
        let hemisphere: String
        if isLatitude {
            hemisphere = value >= 0 ? "N" : "S"
        } else {
            hemisphere = value >= 0 ? "E" : "W"
        }
        let absValue = abs(value)
        let degrees = Int(absValue)
        let minutesFull = (absValue - Double(degrees)) * 60
        let degWidth = isLatitude ? 2 : 3

        switch style {
        case .dms:
            let minutes = Int(minutesFull)
            let seconds = Int((minutesFull - Double(minutes)) * 60 + 0.5)
            // handle rounding to 60
            var m = minutes, s = seconds
            if s == 60 { s = 0; m += 1 }
            return String(format: "%@%0\(degWidth)d°%02d'%02d\"", hemisphere, degrees, m, s)
        case .ddm:
            return String(format: "%@ %0\(degWidth)d°%06.3f'", hemisphere, degrees, minutesFull)
        }
    }
}
