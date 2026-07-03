import XCTest
import SwiftData
@testable import SkipperLogbook

/// Covers the alignment-pass behavior: CSV/GPX export, the engine-owned
/// MOB / anchor logbook logging, and voice-note tag persistence.
@MainActor
final class ExportAndSafetyLoggingTests: XCTestCase {

    private func makeContext() -> ModelContext {
        PersistenceController.makeInMemoryContainer().mainContext
    }

    // MARK: Export — CSV

    func testCSVContainsHeaderAndEscapedRows() throws {
        let context = makeContext()
        let voyage = Voyage(name: "Test voyage")
        context.insert(voyage)
        let event = LogEvent(type: .note, latitude: 43.5, longitude: 5.25,
                             headingDegrees: 90, speedKnots: 5.5,
                             note: "wind, rising \"fast\"")
        event.voyage = voyage
        context.insert(event)
        try context.save()

        let csv = ExportService.csv(for: voyage)
        let lines = csv.split(separator: "\n")
        XCTAssertTrue(lines[0].hasPrefix("timestamp,event,latitude,longitude"))
        XCTAssertEqual(lines.count, 2)                       // header + 1 row
        XCTAssertTrue(csv.contains("\"wind, rising \"\"fast\"\"\""))  // RFC 4180 escaping
        XCTAssertTrue(csv.contains("43.500000"))
        XCTAssertTrue(csv.contains(",note,"))
    }

    // MARK: Export — GPX

    func testGPXContainsTrackWaypointsAndEscaping() throws {
        let context = makeContext()
        let voyage = Voyage(name: "Route <A> & B",
                            destinationName: "Hvar",
                            destinationLat: 43.17, destinationLon: 16.44)
        context.insert(voyage)
        for i in 0..<3 {
            let point = TrackPoint(timestamp: .now.addingTimeInterval(Double(i)),
                                   latitude: 43.0 + Double(i) * 0.001, longitude: 5.0,
                                   speedMps: 2, courseDegrees: 0, propulsion: .sails)
            point.voyage = voyage
            context.insert(point)
        }
        try context.save()

        let gpx = ExportService.gpx(for: voyage)
        XCTAssertTrue(gpx.contains("<gpx version=\"1.1\""))
        XCTAssertEqual(gpx.components(separatedBy: "<trkpt").count - 1, 3)
        XCTAssertTrue(gpx.contains("Route &lt;A&gt; &amp; B"))          // XML escaping
        XCTAssertTrue(gpx.contains("<wpt lat=\"43.17\" lon=\"16.44\">")) // destination waypoint
        XCTAssertTrue(gpx.contains("</gpx>"))
    }

    // MARK: MOB logging (engine-owned, all entry points)

    func testMOBTriggerAndResolveWriteLogEvents() throws {
        let context = makeContext()
        let recorder = VoyageRecorder(context: context)
        recorder.startVoyage(named: "Test")
        let mob = MOBEngine(context: context)

        mob.trigger(at: GeoCoordinate(latitude: 43, longitude: 5), speedKn: 4.2, heading: 180)
        let mobEvents = try context.fetch(FetchDescriptor<LogEvent>()).filter { $0.type == .mob }
        XCTAssertEqual(mobEvents.count, 1)
        XCTAssertEqual(mobEvents.first?.voyage?.name, "Test")   // attached to the recording voyage
        XCTAssertEqual(mobEvents.first?.latitude ?? 0, 43, accuracy: 0.0001)
        XCTAssertEqual(mobEvents.first?.speedKnots ?? 0, 4.2, accuracy: 0.001)

        mob.resolve()
        let points = try context.fetch(FetchDescriptor<MOBPoint>())
        XCTAssertTrue(points.allSatisfy { $0.resolved })
        let resolved = try context.fetch(FetchDescriptor<LogEvent>()).filter { $0.type == .mobResolved }
        XCTAssertEqual(resolved.count, 1)
    }

    func testMOBRetriggerKeepsOriginalIncident() throws {
        let context = makeContext()
        let mob = MOBEngine(context: context)
        let first = mob.trigger(at: GeoCoordinate(latitude: 43, longitude: 5))
        let second = mob.trigger(at: GeoCoordinate(latitude: 44, longitude: 6))

        XCTAssertTrue(first === second)   // same incident, original position kept
        XCTAssertEqual(try context.fetch(FetchDescriptor<MOBPoint>()).count, 1)
        let mobEvents = try context.fetch(FetchDescriptor<LogEvent>()).filter { $0.type == .mob }
        XCTAssertEqual(mobEvents.count, 1)   // no duplicate logbook entry
    }

    func testMOBTriggerLogsWithoutActiveVoyage() throws {
        let context = makeContext()
        let mob = MOBEngine(context: context)
        mob.trigger(at: GeoCoordinate(latitude: 43, longitude: 5))

        let mobEvents = try context.fetch(FetchDescriptor<LogEvent>()).filter { $0.type == .mob }
        XCTAssertEqual(mobEvents.count, 1)
        XCTAssertNil(mobEvents.first?.voyage)   // standalone entry, still logged
    }

    // MARK: Anchor watch logging + alarm latch

    func testAnchorWatchLogsDownUpAndAlarmsOncePerExcursion() throws {
        let context = makeContext()
        let engine = AnchorWatchEngine(context: context)
        let anchor = GeoCoordinate(latitude: 43, longitude: 5)
        engine.start(at: anchor, radiusMeters: 15)

        var events = try context.fetch(FetchDescriptor<LogEvent>())
        XCTAssertEqual(events.filter { $0.type == .anchorDown }.count, 1)

        // Two fixes outside the radius → dragging, but one alarm entry only.
        engine.ingest(NavigationMath.destination(from: anchor, bearingDegrees: 0, distanceMeters: 25))
        engine.ingest(NavigationMath.destination(from: anchor, bearingDegrees: 0, distanceMeters: 30))
        XCTAssertTrue(engine.isDragging)
        events = try context.fetch(FetchDescriptor<LogEvent>())
        XCTAssertEqual(events.filter { $0.type == .anchorAlarm }.count, 1)

        engine.stop()
        events = try context.fetch(FetchDescriptor<LogEvent>())
        XCTAssertEqual(events.filter { $0.type == .anchorUp }.count, 1)
    }

    // MARK: Voice notes

    func testVoiceNoteTagsAndFixRoundTrip() throws {
        let context = makeContext()
        let note = VoiceNote(title: "Reef decision", duration: 10, fileName: "x.m4a",
                             speedKnots: 5.1, courseDegrees: 210,
                             tags: [.sails, .weather])
        context.insert(note)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<VoiceNote>()).first)
        XCTAssertEqual(fetched.tags, [.sails, .weather])
        XCTAssertEqual(fetched.speedKnots ?? 0, 5.1, accuracy: 0.001)
        XCTAssertEqual(fetched.courseDegrees ?? 0, 210, accuracy: 0.001)
    }
}
