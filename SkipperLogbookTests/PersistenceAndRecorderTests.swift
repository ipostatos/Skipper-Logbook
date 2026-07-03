import XCTest
import SwiftData
import CoreLocation
@testable import SkipperLogbook

@MainActor
final class PersistenceAndRecorderTests: XCTestCase {

    private func makeContext() -> ModelContext {
        PersistenceController.makeInMemoryContainer().mainContext
    }

    // MARK: Seeding

    func testSeedInsertsSampleGraph() throws {
        let context = makeContext()
        SeedData.seed(context)
        try context.save()

        let vessels = try context.fetch(FetchDescriptor<Vessel>())
        XCTAssertEqual(vessels.count, 1)
        XCTAssertEqual(vessels.first?.name, "Sea Breeze")
        XCTAssertEqual(vessels.first?.crew.count, 4)

        let voyages = try context.fetch(FetchDescriptor<Voyage>())
        XCTAssertEqual(voyages.count, 2)
        XCTAssertTrue(voyages.allSatisfy { !$0.trackPoints.isEmpty })
        XCTAssertTrue(voyages.allSatisfy { !$0.events.isEmpty })
    }

    func testSeedIfNeededIsIdempotent() throws {
        let context = makeContext()
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!

        SeedData.seedIfNeeded(context, defaults: defaults)
        let firstCount = try context.fetch(FetchDescriptor<Vessel>()).count
        SeedData.seedIfNeeded(context, defaults: defaults)
        let secondCount = try context.fetch(FetchDescriptor<Vessel>()).count

        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1) // no duplicate on second call
    }

    // MARK: Recorder

    func testRecorderAccumulatesDistanceAndTrack() throws {
        let context = makeContext()
        let recorder = VoyageRecorder(context: context)
        recorder.startVoyage(named: "Test")

        // Feed three fixes ~100 m apart.
        var coord = GeoCoordinate(latitude: 43.0, longitude: 5.0)
        for _ in 0..<3 {
            let loc = CLLocation(coordinate: coord.clCoordinate, altitude: 0,
                                 horizontalAccuracy: 5, verticalAccuracy: 5,
                                 course: 90, speed: 3, timestamp: Date())
            recorder.ingest(loc)
            coord = NavigationMath.destination(from: coord, bearingDegrees: 90, distanceMeters: 100)
        }

        let voyage = try XCTUnwrap(recorder.activeVoyage)
        // 3 fixes → 3 track points; distance ~ 200 m (two 100 m legs).
        XCTAssertEqual(voyage.trackPoints.count, 3)
        XCTAssertEqual(voyage.distanceMeters, 200, accuracy: 15)
    }

    func testStopVoyageEndsRecording() throws {
        let context = makeContext()
        let recorder = VoyageRecorder(context: context)
        recorder.startVoyage(named: "Test")
        XCTAssertTrue(recorder.isRecording)
        recorder.stopVoyage()
        XCTAssertFalse(recorder.isRecording)
        XCTAssertNil(recorder.activeVoyage)
    }

    // MARK: Anchor watch

    func testAnchorWatchDistanceAndDrag() throws {
        let context = makeContext()
        let engine = AnchorWatchEngine(context: context)
        let anchor = GeoCoordinate(latitude: 43.0, longitude: 5.0)
        engine.start(at: anchor, radiusMeters: 15)

        // Move 10 m away — within radius, holding.
        let within = NavigationMath.destination(from: anchor, bearingDegrees: 0, distanceMeters: 10)
        engine.ingest(within)
        XCTAssertEqual(engine.currentDistanceMeters, 10, accuracy: 1)
        XCTAssertFalse(engine.isDragging)

        // Move 25 m away — outside radius, dragging.
        let outside = NavigationMath.destination(from: anchor, bearingDegrees: 0, distanceMeters: 25)
        engine.ingest(outside)
        XCTAssertTrue(engine.isDragging)
        XCTAssertEqual(engine.session?.maxDeviationMeters ?? 0, 25, accuracy: 1)
    }

    // MARK: MOB

    func testMOBBearingAndDistance() throws {
        let context = makeContext()
        let mob = MOBEngine(context: context)
        let point = GeoCoordinate(latitude: 43.0, longitude: 5.0)
        mob.trigger(at: point)

        // Boat 100 m due south of the MOB point → bearing back should be ~north (0°).
        let boat = NavigationMath.destination(from: point, bearingDegrees: 180, distanceMeters: 100)
        mob.ingest(boat: boat)
        XCTAssertEqual(mob.distanceMeters, 100, accuracy: 2)
        XCTAssertEqual(mob.bearingDegrees, 0, accuracy: 1)
    }
}
