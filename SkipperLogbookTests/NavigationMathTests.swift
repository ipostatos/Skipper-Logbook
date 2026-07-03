import XCTest
@testable import SkipperLogbook

final class NavigationMathTests: XCTestCase {

    func testHaversineKnownDistance() {
        // ~1 degree of latitude ≈ 111.19 km at the equator.
        let a = GeoCoordinate(latitude: 0, longitude: 0)
        let b = GeoCoordinate(latitude: 1, longitude: 0)
        let meters = NavigationMath.haversineMeters(a, b)
        XCTAssertEqual(meters, 111_195, accuracy: 500)
    }

    func testHaversineZeroForSamePoint() {
        let a = GeoCoordinate(latitude: 43.29, longitude: 5.34)
        XCTAssertEqual(NavigationMath.haversineMeters(a, a), 0, accuracy: 0.001)
    }

    func testBearingEast() {
        let a = GeoCoordinate(latitude: 0, longitude: 0)
        let b = GeoCoordinate(latitude: 0, longitude: 1)
        XCTAssertEqual(NavigationMath.initialBearingDegrees(from: a, to: b), 90, accuracy: 0.5)
    }

    func testBearingNorth() {
        let a = GeoCoordinate(latitude: 0, longitude: 0)
        let b = GeoCoordinate(latitude: 1, longitude: 0)
        XCTAssertEqual(NavigationMath.initialBearingDegrees(from: a, to: b), 0, accuracy: 0.5)
    }

    func testNormalizedDegrees() {
        XCTAssertEqual(NavigationMath.normalizedDegrees(-10), 350, accuracy: 0.001)
        XCTAssertEqual(NavigationMath.normalizedDegrees(370), 10, accuracy: 0.001)
        XCTAssertEqual(NavigationMath.normalizedDegrees(720), 0, accuracy: 0.001)
    }

    func testAngularDifferenceWraps() {
        XCTAssertEqual(NavigationMath.angularDifference(from: 350, to: 10), 20, accuracy: 0.001)
        XCTAssertEqual(NavigationMath.angularDifference(from: 10, to: 350), -20, accuracy: 0.001)
    }

    func testETANilAtZeroSpeed() {
        XCTAssertNil(NavigationMath.etaSeconds(distanceMeters: 1000, speedMps: 0))
        XCTAssertNotNil(NavigationMath.etaSeconds(distanceMeters: 1000, speedMps: 5))
    }

    func testETAValue() {
        // 1852 m at 1 m/s = 1852 s.
        let eta = NavigationMath.etaSeconds(distanceMeters: 1852, speedMps: 1)
        XCTAssertEqual(eta ?? 0, 1852, accuracy: 0.001)
    }

    func testDestinationRoundTrip() {
        let origin = GeoCoordinate(latitude: 43.29, longitude: 5.34)
        let moved = NavigationMath.destination(from: origin, bearingDegrees: 90, distanceMeters: 1000)
        let back = NavigationMath.haversineMeters(origin, moved)
        XCTAssertEqual(back, 1000, accuracy: 1)
    }

    func testUnitConversions() {
        XCTAssertEqual(Units.metersToNM(1852), 1, accuracy: 0.0001)
        XCTAssertEqual(Units.mpsToKnots(1), 1.943844, accuracy: 0.0001)
        XCTAssertEqual(Units.mpsToKnots(-5), 0, accuracy: 0.0001) // clamps negatives
    }

    func testTrackLength() {
        let pts = [
            GeoCoordinate(latitude: 0, longitude: 0),
            GeoCoordinate(latitude: 0, longitude: 1),
            GeoCoordinate(latitude: 0, longitude: 2)
        ]
        let total = NavigationMath.trackLengthMeters(pts)
        let expected = NavigationMath.haversineMeters(pts[0], pts[1])
                     + NavigationMath.haversineMeters(pts[1], pts[2])
        XCTAssertEqual(total, expected, accuracy: 0.001)
    }
}
