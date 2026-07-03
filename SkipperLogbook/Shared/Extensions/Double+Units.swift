import Foundation

extension Double {
    /// Formats with a fixed number of fraction digits, no trailing zeros beyond it.
    func formatted(_ fractionDigits: Int) -> String {
        String(format: "%.\(fractionDigits)f", self)
    }

    /// "2.5" for speeds/distances shown to one decimal.
    var oneDecimal: String { formatted(1) }
}

/// Nautical / metric unit helpers used across instruments and stats.
enum Units {
    static let metersPerNauticalMile = 1_852.0
    static let knotsPerMps = 1.943_844

    static func metersToNM(_ meters: Double) -> Double { meters / metersPerNauticalMile }
    static func nmToMeters(_ nm: Double) -> Double { nm * metersPerNauticalMile }
    static func mpsToKnots(_ mps: Double) -> Double { max(0, mps) * knotsPerMps }
    static func knotsToMps(_ kn: Double) -> Double { kn / knotsPerMps }

    /// "2.5 kn", "186.2 nm", "56 m" — value + unit for display.
    static func knots(_ kn: Double) -> String { "\(kn.oneDecimal) kn" }
    static func nauticalMiles(_ nm: Double) -> String { "\(nm.oneDecimal) nm" }
    static func meters(_ m: Double) -> String { "\(Int(m.rounded())) m" }
    static func degrees(_ deg: Double) -> String { "\(Int(deg.rounded()))°" }
}
