import Foundation
import SwiftData

/// Provides an in-memory container pre-filled with sample data for SwiftUI
/// `#Preview`s. Never used by the running app.
@MainActor
enum PreviewData {

    /// A shared, seeded in-memory container. Reused across previews in a run.
    static let container: ModelContainer = {
        let container = PersistenceController.makeInMemoryContainer()
        SeedData.seed(container.mainContext)
        try? container.mainContext.save()
        return container
    }()

    /// The seeded vessel, for previews that need a concrete object.
    static var sampleVessel: Vessel {
        (try? container.mainContext.fetch(FetchDescriptor<Vessel>()))?.first
            ?? Vessel(name: "Sea Breeze")
    }

    /// The most recent voyage, for dashboard/map/log previews.
    static var sampleVoyage: Voyage {
        let descriptor = FetchDescriptor<Voyage>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? container.mainContext.fetch(descriptor))?.first
            ?? Voyage(name: "Preview voyage")
    }
}
