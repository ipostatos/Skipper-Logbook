import Foundation

/// The app group identifier shared between the app and its widget/Live Activity
/// extension. Must match the App Group capability on both targets.
enum AppGroup {
    static let identifier = "group.com.skipperlogbook.app"
}

/// A tiny, Codable snapshot of the current voyage state. The app writes it to the
/// shared App Group container whenever the voyage updates; the widget and Live
/// Activity read it. Widgets can't open the SwiftData store cleanly, so this
/// lightweight snapshot is the shared contract.
struct VoyageSnapshot: Codable, Equatable {
    var isRecording: Bool
    var voyageName: String
    var origin: String?           // e.g. "Split"
    var destination: String?      // e.g. "Hvar"

    var speedKn: Double
    var courseDegrees: Double
    var distanceNM: Double
    var remainingNM: Double?
    var etaEpoch: Double?         // absolute ETA as a time interval since 1970
    var fuelPercent: Double?

    // Maintenance (for the maintenance widget)
    var nextServiceTitle: String?
    var nextServiceHoursLeft: Double?

    // Streak (for the logbook streak widget)
    var voyagesThisMonth: Int
    var milesThisMonth: Double

    var updatedEpoch: Double

    static let placeholder = VoyageSnapshot(
        isRecording: true,
        voyageName: "Split → Hvar",
        origin: "Split", destination: "Hvar",
        speedKn: 2.8, courseDegrees: 196, distanceNM: 12.4, remainingNM: 4.6,
        etaEpoch: nil, fuelPercent: 68,
        nextServiceTitle: "Oil change", nextServiceHoursLeft: 12,
        voyagesThisMonth: 7, milesThisMonth: 128,
        updatedEpoch: 0
    )

    static let empty = VoyageSnapshot(
        isRecording: false, voyageName: "", origin: nil, destination: nil,
        speedKn: 0, courseDegrees: 0, distanceNM: 0, remainingNM: nil,
        etaEpoch: nil, fuelPercent: nil,
        nextServiceTitle: nil, nextServiceHoursLeft: nil,
        voyagesThisMonth: 0, milesThisMonth: 0, updatedEpoch: 0
    )
}

/// Reads/writes the shared `VoyageSnapshot` in the App Group container.
enum SharedStore {
    private static let key = "voyageSnapshot.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroup.identifier)
    }

    static func write(_ snapshot: VoyageSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func read() -> VoyageSnapshot {
        guard let defaults, let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(VoyageSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
