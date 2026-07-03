import Foundation
import SwiftData

/// A completed service / maintenance record on the vessel's machinery.
/// Next-service fields are stored but scheduling/reminders are "Coming soon".
@Model
final class MaintenanceItem {
    var title: String                // "Oil change" / "Замена масла"
    var detail: String?              // "Motor Oil 15W-40"
    var performedAt: Date
    var engineHoursAtService: Double?

    // Optional next-service targets (display-only in BETA)
    var nextServiceHours: Double?
    var nextServiceDate: Date?

    var vessel: Vessel?

    init(
        title: String,
        detail: String? = nil,
        performedAt: Date = .now,
        engineHoursAtService: Double? = nil,
        nextServiceHours: Double? = nil,
        nextServiceDate: Date? = nil
    ) {
        self.title = title
        self.detail = detail
        self.performedAt = performedAt
        self.engineHoursAtService = engineHoursAtService
        self.nextServiceHours = nextServiceHours
        self.nextServiceDate = nextServiceDate
    }
}
