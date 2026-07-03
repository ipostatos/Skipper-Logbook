import Foundation
import SwiftData

/// The boat. A single vessel is the "current" one for the MVP, but the schema
/// supports several. Holds identity/registration data and owns crew, maintenance
/// and equipment records.
@Model
final class Vessel {
    var name: String
    var type: String                 // "Sailboat" / "Парусная яхта"
    var isSail: Bool                 // sail vs motor — affects available instruments

    @Attribute(.externalStorage) var photoData: Data?

    // Registration / identity
    var registration: String?
    var mmsi: String?
    var callSign: String?

    // Dimensions (metres) and machinery
    var lengthMeters: Double?
    var beamMeters: Double?
    var draftMeters: Double?
    var engineModel: String?
    var fuelCapacityLiters: Double?
    var waterCapacityLiters: Double?
    /// Free-form captain's notes about the boat.
    var notes: String = ""

    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CrewMember.vessel)
    var crew: [CrewMember]

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceItem.vessel)
    var maintenanceItems: [MaintenanceItem]

    @Relationship(deleteRule: .cascade, inverse: \EquipmentItem.vessel)
    var equipment: [EquipmentItem]

    @Relationship(deleteRule: .cascade, inverse: \DeviationEntry.vessel)
    var deviationTable: [DeviationEntry]

    init(
        name: String,
        type: String = "Sailboat",
        isSail: Bool = true,
        photoData: Data? = nil,
        registration: String? = nil,
        mmsi: String? = nil,
        callSign: String? = nil,
        lengthMeters: Double? = nil,
        beamMeters: Double? = nil,
        draftMeters: Double? = nil,
        engineModel: String? = nil,
        fuelCapacityLiters: Double? = nil,
        waterCapacityLiters: Double? = nil,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.type = type
        self.isSail = isSail
        self.photoData = photoData
        self.registration = registration
        self.mmsi = mmsi
        self.callSign = callSign
        self.lengthMeters = lengthMeters
        self.beamMeters = beamMeters
        self.draftMeters = draftMeters
        self.engineModel = engineModel
        self.fuelCapacityLiters = fuelCapacityLiters
        self.waterCapacityLiters = waterCapacityLiters
        self.notes = notes
        self.createdAt = createdAt
        self.crew = []
        self.maintenanceItems = []
        self.equipment = []
        self.deviationTable = []
    }
}
