import Foundation
import SwiftData

/// A timestamped logbook entry. Beyond the basic fix (position/heading/speed) it
/// carries an optional free-text note, a wind/weather observation, and per-sail
/// set percentages — matching the rich log rows in the screenshots
/// ("Mainsail 75% · Jib 75%", "The wind increased to 20 knots, took 1 reef bar").
@Model
final class LogEvent {
    var timestamp: Date
    var typeRaw: String

    // Fix at the moment of the entry
    var latitude: Double?
    var longitude: Double?
    var headingDegrees: Double?
    var speedKnots: Double?
    /// Distance-into-voyage at this entry (nm), shown at the row's trailing edge.
    var legDistanceNM: Double?

    // Rich content
    var note: String?                 // free text
    var windDirection: String?        // "CEE", "NW", compass point / label
    var windSpeedKn: Double?          // e.g. 20

    // Sail state (nil = not applicable to this event)
    var mainsailPercent: Int?         // 0…100, nil if main not involved
    var jibPercent: Int?              // headsail (jib / genoa) 0…100

    var voyage: Voyage?

    init(
        type: LogEventType,
        timestamp: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil,
        headingDegrees: Double? = nil,
        speedKnots: Double? = nil,
        legDistanceNM: Double? = nil,
        note: String? = nil,
        windDirection: String? = nil,
        windSpeedKn: Double? = nil,
        mainsailPercent: Int? = nil,
        jibPercent: Int? = nil
    ) {
        self.typeRaw = type.rawValue
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.headingDegrees = headingDegrees
        self.speedKnots = speedKnots
        self.legDistanceNM = legDistanceNM
        self.note = note
        self.windDirection = windDirection
        self.windSpeedKn = windSpeedKn
        self.mainsailPercent = mainsailPercent
        self.jibPercent = jibPercent
    }

    var type: LogEventType {
        get { LogEventType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    var coordinate: GeoCoordinate? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return GeoCoordinate(latitude: lat, longitude: lon)
    }

    var hasSailState: Bool { mainsailPercent != nil || jibPercent != nil }

    /// Inserts a logbook entry attached to the currently-recording voyage (if
    /// any). The single writer shared by the safety engines, so every entry
    /// point logs identically — new fields are threaded through one place.
    @discardableResult
    static func record(_ type: LogEventType,
                       in context: ModelContext,
                       at coordinate: GeoCoordinate? = nil,
                       heading: Double? = nil,
                       speedKn: Double? = nil,
                       note: String? = nil) -> LogEvent {
        let voyage = Voyage.recording(in: context)
        let event = LogEvent(type: type,
                             latitude: coordinate?.latitude,
                             longitude: coordinate?.longitude,
                             headingDegrees: heading,
                             speedKnots: speedKn,
                             legDistanceNM: voyage?.distanceNM,
                             note: note)
        event.voyage = voyage
        context.insert(event)
        return event
    }

    var hasWind: Bool { windSpeedKn != nil || (windDirection?.isEmpty == false) }

    /// "CEE 20kn" style wind summary if present.
    var windSummary: String? {
        guard hasWind else { return nil }
        let dir = windDirection ?? ""
        if let kn = windSpeedKn {
            return "\(dir) \(Int(kn.rounded()))kn".trimmingCharacters(in: .whitespaces)
        }
        return dir.isEmpty ? nil : dir
    }
}
