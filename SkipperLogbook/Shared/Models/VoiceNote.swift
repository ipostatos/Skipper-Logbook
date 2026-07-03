import Foundation
import SwiftData
import SwiftUI

/// Quick categorization for voice notes — the same vocabulary as the quick
/// events, so a note filed from the helm lands in the right bucket.
enum VoiceTag: String, Codable, CaseIterable, Identifiable {
    case weather, engine, sails, crew, issue

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .weather: return "voice.tag_weather"
        case .engine:  return "voice.tag_engine"
        case .sails:   return "voice.tag_sails"
        case .crew:    return "voice.tag_crew"
        case .issue:   return "voice.tag_issue"
        }
    }

    var symbol: String {
        switch self {
        case .weather: return "cloud.sun"
        case .engine:  return "engine.combustion"
        case .sails:   return "sailboat"
        case .crew:    return "person.2"
        case .issue:   return "exclamationmark.triangle"
        }
    }
}

/// A recorded audio note ("Voice Log"). The audio file lives in the app's
/// Documents directory; we persist its filename plus metadata for the list.
@Model
final class VoiceNote {
    var title: String                 // "Squall to the NW", "Reef decision"
    var createdAt: Date
    var duration: TimeInterval        // seconds
    var fileName: String              // relative to Documents/VoiceNotes
    var transcript: String?           // optional, future
    // Fix at recording time (optional — recording works without GPS)
    var latitude: Double?
    var longitude: Double?
    var speedKnots: Double?
    var courseDegrees: Double?
    /// Comma-joined `VoiceTag` raw values (SwiftData-friendly storage).
    var tagsRaw: String = ""

    var voyage: Voyage?

    init(
        title: String,
        createdAt: Date = .now,
        duration: TimeInterval,
        fileName: String,
        transcript: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        speedKnots: Double? = nil,
        courseDegrees: Double? = nil,
        tags: [VoiceTag] = []
    ) {
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.fileName = fileName
        self.transcript = transcript
        self.latitude = latitude
        self.longitude = longitude
        self.speedKnots = speedKnots
        self.courseDegrees = courseDegrees
        self.tagsRaw = tags.map(\.rawValue).joined(separator: ",")
    }

    var tags: [VoiceTag] {
        get { tagsRaw.split(separator: ",").compactMap { VoiceTag(rawValue: String($0)) } }
        set { tagsRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }
}
