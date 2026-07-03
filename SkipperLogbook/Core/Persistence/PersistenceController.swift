import Foundation
import SwiftData

/// Central SwiftData configuration. Declares the full schema once so both the
/// app container and the in-memory preview/test container stay in sync.
enum PersistenceController {

    /// Every `@Model` type in the app. Keep this exhaustive — a missing type
    /// causes a fatal "no such entity" at runtime.
    static let schema = Schema([
        Voyage.self,
        TrackPoint.self,
        LogEvent.self,
        VoiceNote.self,
        Vessel.self,
        CrewMember.self,
        MaintenanceItem.self,
        EquipmentItem.self,
        DeviationEntry.self,
        ServiceNote.self,
        SeasonLogEntry.self,
        AnchorWatchSession.self,
        MOBPoint.self
    ])

    /// The on-disk container used by the running app.
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // A schema/store mismatch here is a programmer error; fail loudly.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// An ephemeral container for SwiftUI previews and unit tests.
    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
