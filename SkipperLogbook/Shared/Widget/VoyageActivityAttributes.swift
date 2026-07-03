import Foundation
import ActivityKit

/// Live Activity attributes for an active voyage. Shared by the app (which
/// starts/updates the activity) and the widget extension (which renders it in
/// the Dynamic Island / Lock Screen).
struct VoyageActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var speedKn: Double
        var courseDegrees: Double
        var distanceNM: Double
        var remainingNM: Double?
        var etaEpoch: Double?
        var progress: Double     // 0…1 route progress
        var isRecording: Bool
    }

    // Static for the life of the activity
    var voyageName: String
    var origin: String?
    var destination: String?
}
