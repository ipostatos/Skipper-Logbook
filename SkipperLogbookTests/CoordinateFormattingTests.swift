import XCTest
@testable import SkipperLogbook

final class CoordinateFormattingTests: XCTestCase {

    func testDMSNorthEast() {
        let coord = GeoCoordinate(latitude: 43.287777, longitude: 5.342500)
        let lat = CoordinateFormatting.latitudeString(coord.latitude, style: .dms)
        let lon = CoordinateFormatting.longitudeString(coord.longitude, style: .dms)
        XCTAssertTrue(lat.hasPrefix("N43°"), "got \(lat)")
        XCTAssertTrue(lon.hasPrefix("E005°"), "got \(lon)")
    }

    func testDMSSouthWestHemispheres() {
        XCTAssertTrue(CoordinateFormatting.latitudeString(-1, style: .dms).hasPrefix("S"))
        XCTAssertTrue(CoordinateFormatting.longitudeString(-1, style: .dms).hasPrefix("W"))
    }

    func testDDMFormat() {
        let s = CoordinateFormatting.latitudeString(59.957, style: .ddm)
        XCTAssertTrue(s.hasPrefix("N 59°"), "got \(s)")
        XCTAssertTrue(s.contains("'"), "got \(s)")
    }

    func testLongitudeThreeDigitDegrees() {
        let s = CoordinateFormatting.longitudeString(5.34, style: .dms)
        // longitude degrees are zero-padded to three digits
        XCTAssertTrue(s.contains("005°"), "got \(s)")
    }
}
