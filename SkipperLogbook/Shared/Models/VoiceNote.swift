import Foundation
import SwiftData

/// A recorded audio note ("Voice Log"). The audio file lives in the app's
/// Documents directory; we persist its filename plus metadata for the list.
@Model
final class VoiceNote {
    var title: String                 // "Squall to the NW", "Reef decision"
    var createdAt: Date
    var duration: TimeInterval        // seconds
    var fileName: String              // relative to Documents/VoiceNotes
    var transcript: String?           // optional, future
    // Position at recording time (optional)
    var latitude: Double?
    var longitude: Double?

    var voyage: Voyage?

    init(
        title: String,
        createdAt: Date = .now,
        duration: TimeInterval,
        fileName: String,
        transcript: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.fileName = fileName
        self.transcript = transcript
        self.latitude = latitude
        self.longitude = longitude
    }
}
