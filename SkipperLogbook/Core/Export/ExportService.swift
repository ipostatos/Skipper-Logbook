import Foundation

enum ExportError: Error {
    case notImplemented
}

/// Voyage export. CSV (one row per log entry) and GPX 1.1 (waypoints + the
/// recorded track) are real and shared from the voyage detail screen. PDF is
/// still Coming soon — its buttons stay disabled, no fake implementation.
enum ExportService {

    /// PDF export is not implemented yet; Settings keeps that row disabled.
    static let isPDFAvailable = false

    // MARK: CSV

    /// RFC 4180-style CSV of the voyage's log entries, ISO 8601 timestamps,
    /// nautical units (kn / nm) as in the app.
    static func csv(for voyage: Voyage) -> String {
        var lines = ["timestamp,event,latitude,longitude,course_deg,speed_kn,distance_nm,wind,mainsail_pct,jib_pct,note"]
        let iso = ISO8601DateFormatter()
        for e in voyage.events.sorted(by: { $0.timestamp < $1.timestamp }) {
            let fields: [String] = [
                iso.string(from: e.timestamp),
                e.type.rawValue,
                e.latitude.map { String(format: "%.6f", $0) } ?? "",
                e.longitude.map { String(format: "%.6f", $0) } ?? "",
                e.headingDegrees.map { String(format: "%.0f", $0) } ?? "",
                e.speedKnots.map { String(format: "%.1f", $0) } ?? "",
                e.legDistanceNM.map { String(format: "%.2f", $0) } ?? "",
                e.windSummary ?? "",
                e.mainsailPercent.map(String.init) ?? "",
                e.jibPercent.map(String.init) ?? "",
                e.note ?? ""
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvEscape(_ field: String) -> String {
        guard field.contains(where: { ",\"\n\r".contains($0) }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: GPX

    /// GPX 1.1: voyage metadata, the destination and positioned log entries as
    /// `<wpt>`, and the recorded track as a single `<trkseg>`.
    static func gpx(for voyage: Voyage) -> String {
        let iso = ISO8601DateFormatter()
        var out = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        out += "<gpx version=\"1.1\" creator=\"Skipper Logbook\" "
        out += "xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        out += "  <metadata><name>\(xmlEscape(voyage.name))</name>"
        out += "<time>\(iso.string(from: voyage.startedAt))</time></metadata>\n"

        if let dest = voyage.destination {
            out += "  <wpt lat=\"\(dest.latitude)\" lon=\"\(dest.longitude)\">"
            out += "<name>\(xmlEscape(voyage.destinationName ?? "Waypoint"))</name></wpt>\n"
        }
        for e in voyage.events.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let lat = e.latitude, let lon = e.longitude else { continue }
            out += "  <wpt lat=\"\(lat)\" lon=\"\(lon)\">"
            out += "<time>\(iso.string(from: e.timestamp))</time>"
            out += "<name>\(xmlEscape(e.type.rawValue))</name>"
            if let note = e.note, !note.isEmpty { out += "<desc>\(xmlEscape(note))</desc>" }
            out += "</wpt>\n"
        }

        out += "  <trk><name>\(xmlEscape(voyage.name))</name><trkseg>\n"
        for p in voyage.orderedTrack {
            out += "    <trkpt lat=\"\(p.latitude)\" lon=\"\(p.longitude)\">"
            out += "<time>\(iso.string(from: p.timestamp))</time></trkpt>\n"
        }
        out += "  </trkseg></trk>\n</gpx>\n"
        return out
    }

    private static func xmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    // MARK: Shareable files

    static func writeCSV(for voyage: Voyage) throws -> URL {
        try write(csv(for: voyage), name: fileName(for: voyage, ext: "csv"))
    }

    static func writeGPX(for voyage: Voyage) throws -> URL {
        try write(gpx(for: voyage), name: fileName(for: voyage, ext: "gpx"))
    }

    private static func fileName(for voyage: Voyage, ext: String) -> String {
        let safe = voyage.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return "\(safe.isEmpty ? "voyage" : safe).\(ext)"
    }

    private static func write(_ content: String, name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
