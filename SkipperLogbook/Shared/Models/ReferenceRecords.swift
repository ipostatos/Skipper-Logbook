import Foundation
import SwiftData

/// A piece of onboard equipment / inventory (life raft, EPIRB, flares…).
/// Surfaced from the More ▸ Equipment List section.
@Model
final class EquipmentItem {
    var name: String
    var category: String?            // "Safety", "Navigation", "Deck"…
    var quantity: Int
    var detail: String?
    var expiresAt: Date?             // e.g. flare / raft service expiry
    var vessel: Vessel?

    init(name: String, category: String? = nil, quantity: Int = 1,
         detail: String? = nil, expiresAt: Date? = nil) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.detail = detail
        self.expiresAt = expiresAt
    }
}

/// One row of the compass deviation table: heading → deviation (° East +/West −).
@Model
final class DeviationEntry {
    var headingDegrees: Double       // ship's head (compass), e.g. 0,15,30…
    var deviationDegrees: Double     // + East, − West
    var vessel: Vessel?

    init(headingDegrees: Double, deviationDegrees: Double) {
        self.headingDegrees = headingDegrees
        self.deviationDegrees = deviationDegrees
    }
}

/// A free-form service / repair note (More ▸ Service Notes). Distinct from the
/// structured `MaintenanceItem` — this is the captain's running notebook.
@Model
final class ServiceNote {
    var title: String
    var body: String
    var createdAt: Date
    var engineHours: Double?

    init(title: String, body: String, createdAt: Date = .now, engineHours: Double? = nil) {
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.engineHours = engineHours
    }
}

/// A season summary entry (More ▸ Season Log): miles, engine hours, notes per season.
@Model
final class SeasonLogEntry {
    var seasonName: String           // "2025"
    var startedAt: Date
    var endedAt: Date?
    var totalDistanceNM: Double
    var engineHours: Double
    var notes: String?

    init(seasonName: String, startedAt: Date, endedAt: Date? = nil,
         totalDistanceNM: Double = 0, engineHours: Double = 0, notes: String? = nil) {
        self.seasonName = seasonName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.totalDistanceNM = totalDistanceNM
        self.engineHours = engineHours
        self.notes = notes
    }
}
