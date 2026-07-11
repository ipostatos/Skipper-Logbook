import Foundation
import SwiftData
import os

/// Central SwiftData configuration. Declares the full schema once so both the
/// app container and the in-memory preview/test container stay in sync.
enum PersistenceController {

    private static let log = Logger(subsystem: "com.skipperlogbook.app", category: "Persistence")

    /// Every `@Model` type in the app. Keep this exhaustive — a missing type
    /// causes a fatal "no such entity" at runtime.
    static let schema = Schema(versionedSchema: SchemaV1.self)

    /// Set when the on-disk store could not be opened and had to be moved
    /// aside — the UI shows a one-time "your data was backed up" alert.
    private(set) static var storeWasReset = false

    /// The on-disk container used by the running app.
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema,
                                      migrationPlan: SkipperMigrationPlan.self,
                                      configurations: [config])
        } catch {
            // Never silently destroy the user's logbook and never brick the
            // app with fatalError: move the unreadable store into a dated
            // backup folder and start clean. The alert tells the user.
            log.fault("Store failed to open, backing it up: \(error)")
            backUpStore(at: config.url)
            storeWasReset = true
            do {
                return try ModelContainer(for: schema,
                                          migrationPlan: SkipperMigrationPlan.self,
                                          configurations: [config])
            } catch {
                // Even a fresh store failed (disk full / sandbox issue) — run
                // on an in-memory container so the app still opens; nothing
                // the user had is lost (the files are backed up / untouched).
                log.fault("Fresh store also failed, falling back to in-memory: \(error)")
                return makeInMemoryContainer()
            }
        }
    }

    /// An ephemeral container for SwiftUI previews and unit tests.
    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // In-memory creation only fails on programmer error (bad schema);
            // there is no user data at stake here.
            fatalError("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    /// Moves the store file plus its -wal/-shm sidecars into
    /// `Application Support/CorruptedStore-<timestamp>/` so nothing is lost.
    private static func backUpStore(at storeURL: URL) {
        let fm = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let backupDir = storeURL.deletingLastPathComponent()
            .appendingPathComponent("CorruptedStore-\(stamp)", isDirectory: true)
        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: storeURL.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            try? fm.moveItem(at: source,
                             to: backupDir.appendingPathComponent(source.lastPathComponent))
        }
        log.warning("Store backed up to \(backupDir.path)")
    }
}

// MARK: - Versioned schema

/// V1 — the shipped schema. New versions get their own enum + a migration
/// stage in `SkipperMigrationPlan`; never mutate this list retroactively.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Voyage.self,
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
         MOBPoint.self]
    }
}

enum SkipperMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
