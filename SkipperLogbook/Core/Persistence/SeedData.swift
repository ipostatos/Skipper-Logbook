import Foundation
import SwiftData

/// Populates the store with sample content on first launch so the app looks
/// alive and mirrors the mockups (vessel "Sea Breeze", crew, maintenance,
/// recent voyages with tracks and rich log entries, an MOB point, an anchor
/// session and reference records). Idempotent — guarded by a defaults flag AND
/// an existence check, so calling it twice is a no-op.
enum SeedData {

    private static let didSeedKey = "seed.didSeedV1"

    /// Seeds if the store has never been seeded. Safe to call on every launch.
    static func seedIfNeeded(_ context: ModelContext,
                             defaults: UserDefaults = .standard,
                             now: Date = .now) {
        if defaults.bool(forKey: didSeedKey) { return }

        // Guard against re-seeding a store that already has a vessel.
        let existing = try? context.fetch(FetchDescriptor<Vessel>())
        guard (existing?.isEmpty ?? true) else {
            defaults.set(true, forKey: didSeedKey)
            return
        }

        seed(context, now: now)
        try? context.save()
        defaults.set(true, forKey: didSeedKey)
    }

    /// Inserts the sample graph. Exposed (internal) so tests can call it against
    /// an in-memory context without touching UserDefaults.
    static func seed(_ context: ModelContext, now: Date = .now) {
        let cal = Calendar.current

        // MARK: Vessel — "Sea Breeze"
        let vessel = Vessel(
            name: "Sea Breeze",
            type: "Sailing yacht",
            isSail: true,
            registration: "POL 12345",
            mmsi: "273123456",
            callSign: "SP1234",
            lengthMeters: 11.58,
            beamMeters: 3.75,
            draftMeters: 1.90,
            engineModel: "Volvo D2-50",
            fuelCapacityLiters: 120
        )
        context.insert(vessel)

        // MARK: Crew
        let crew = [
            CrewMember(name: "Артём", role: "Captain",  phone: "+48 123 456 789", sortIndex: 0),
            CrewMember(name: "Мария", role: "Navigator", phone: "+48 987 654 321", sortIndex: 1),
            CrewMember(name: "Иван",  role: "Deckhand",  phone: "+48 555 111 222", sortIndex: 2),
            CrewMember(name: "Олег",  role: "Engineer",  phone: "+48 333 666 777", sortIndex: 3)
        ]
        crew.forEach { $0.vessel = vessel; context.insert($0) }

        // MARK: Maintenance
        let maintenance = [
            MaintenanceItem(title: "Oil change", detail: "Motor Oil 15W-40",
                            performedAt: date(cal, now, daysAgo: 23), engineHoursAtService: 185,
                            nextServiceHours: 200, nextServiceDate: date(cal, now, daysInFuture: 15)),
            MaintenanceItem(title: "Fuel filter", detail: "Racor 500FG",
                            performedAt: date(cal, now, daysAgo: 59), engineHoursAtService: 180),
            MaintenanceItem(title: "Alternator belt", detail: "OEM Volvo",
                            performedAt: date(cal, now, daysAgo: 44), engineHoursAtService: 170)
        ]
        maintenance.forEach { $0.vessel = vessel; context.insert($0) }

        // MARK: Equipment & deviation (reference sections)
        let equipment = [
            EquipmentItem(name: "Life raft", category: "Safety", quantity: 1, detail: "6-person, valise",
                          expiresAt: date(cal, now, daysInFuture: 300)),
            EquipmentItem(name: "EPIRB", category: "Safety", quantity: 1, detail: "GPS 406 MHz"),
            EquipmentItem(name: "Flares", category: "Safety", quantity: 12, detail: "Red parachute + handheld",
                          expiresAt: date(cal, now, daysInFuture: 120)),
            EquipmentItem(name: "Handheld VHF", category: "Navigation", quantity: 1)
        ]
        equipment.forEach { $0.vessel = vessel; context.insert($0) }

        for heading in stride(from: 0, through: 345, by: 15) {
            let dev = (sin(Double(heading) * .pi / 180) * 3).rounded() // small synthetic curve
            let entry = DeviationEntry(headingDegrees: Double(heading), deviationDegrees: dev)
            entry.vessel = vessel
            context.insert(entry)
        }

        context.insert(ServiceNote(title: "Winter haul-out",
                                   body: "Antifouling applied, sail drive serviced, anodes replaced.",
                                   createdAt: date(cal, now, daysAgo: 120), engineHours: 160))

        context.insert(SeasonLogEntry(seasonName: "2025",
                                      startedAt: date(cal, now, daysAgo: 120),
                                      totalDistanceNM: 486, engineHours: 39.7,
                                      notes: "Baltic cruise + weekend sails."))

        // MARK: Voyages with tracks + rich log entries
        let baltika = makeVoyage(
            context, name: "Балтика 2025",
            startedAt: date(cal, now, daysAgo: 21),
            durationHours: 5.5, distanceNM: 23.4,
            origin: GeoCoordinate(latitude: 59.957, longitude: 30.311)
        )
        let outing = makeVoyage(
            context, name: "Выход в море",
            startedAt: date(cal, now, daysAgo: 25),
            durationHours: 3.2, distanceNM: 12.7,
            origin: GeoCoordinate(latitude: 59.940, longitude: 30.300)
        )
        _ = (baltika, outing)

        // MARK: MOB sample point (resolved)
        let mob = MOBPoint(timestamp: date(cal, now, daysAgo: 21, addingHours: 3),
                           latitude: 60.035, longitude: 30.497, resolved: true,
                           resolvedAt: date(cal, now, daysAgo: 21, addingHours: 3.1))
        context.insert(mob)
    }

    // MARK: - Helpers

    private static func makeVoyage(_ context: ModelContext, name: String,
                                   startedAt: Date, durationHours: Double,
                                   distanceNM: Double, origin: GeoCoordinate) -> Voyage {
        let voyage = Voyage(name: name, startedAt: startedAt,
                            endedAt: startedAt.addingTimeInterval(durationHours * 3600),
                            isRecording: false,
                            distanceMeters: Units.nmToMeters(distanceNM),
                            engineSeconds: 0.3 * 3600,
                            fuelUsedLiters: 3.2,
                            destinationName: "Маяк Северный")
        context.insert(voyage)

        // Synthetic track: 12 points curving away from origin.
        let steps = 12
        let legMeters = Units.nmToMeters(distanceNM) / Double(steps)
        var here = origin
        var bearing = 20.0
        for i in 0...steps {
            let t = startedAt.addingTimeInterval(durationHours * 3600 * Double(i) / Double(steps))
            let speed = Units.knotsToMps(4 + 2 * sin(Double(i)))   // 2…6 kn wobble
            let mode: PropulsionMode = i < 2 ? .engine : (i % 4 == 0 ? .sailsAndEngine : .sails)
            let point = TrackPoint(timestamp: t,
                                   latitude: here.latitude, longitude: here.longitude,
                                   speedMps: speed, courseDegrees: bearing, propulsion: mode)
            point.voyage = voyage
            context.insert(point)
            bearing = NavigationMath.normalizedDegrees(bearing + 6)
            here = NavigationMath.destination(from: here, bearingDegrees: bearing, distanceMeters: legMeters)
        }

        // Rich log entries mirroring the Журнал / Logs screenshots.
        let entries: [LogEvent] = [
            LogEvent(type: .startLogging, timestamp: startedAt,
                     latitude: origin.latitude, longitude: origin.longitude,
                     headingDegrees: 304, speedKnots: 0, legDistanceNM: 0,
                     note: "Start logging"),
            LogEvent(type: .startTrack, timestamp: startedAt.addingTimeInterval(30),
                     latitude: origin.latitude, longitude: origin.longitude,
                     headingDegrees: 304, speedKnots: 0, legDistanceNM: 0,
                     note: "Start record track"),
            LogEvent(type: .engineOn, timestamp: startedAt.addingTimeInterval(60),
                     latitude: 59.957, longitude: 30.311, headingDegrees: 102,
                     speedKnots: 3.2, legDistanceNM: 0.0),
            LogEvent(type: .sailsUp, timestamp: startedAt.addingTimeInterval(15 * 60),
                     latitude: 59.9583, longitude: 30.213, headingDegrees: 118,
                     speedKnots: 5.6, legDistanceNM: 1.2,
                     mainsailPercent: 100, jibPercent: 100),
            LogEvent(type: .engineOff, timestamp: startedAt.addingTimeInterval(18 * 60),
                     latitude: 59.9585, longitude: 30.215, headingDegrees: 118, speedKnots: 5.4),
            LogEvent(type: .reef, timestamp: startedAt.addingTimeInterval(60 * 60),
                     latitude: 60.001, longitude: 30.258, headingDegrees: 196,
                     speedKnots: 6.1, legDistanceNM: 1.2,
                     note: "The wind increased to 20 knots, took 1 reef.",
                     windDirection: "CEE", windSpeedKn: 20,
                     mainsailPercent: 75, jibPercent: 75),
            LogEvent(type: .turnToWaypoint, timestamp: startedAt.addingTimeInterval(100 * 60),
                     latitude: 60.0011, longitude: 30.2575, headingDegrees: 196, speedKnots: 6.1),
            LogEvent(type: .anchorDown, timestamp: startedAt.addingTimeInterval(160 * 60),
                     latitude: 60.015, longitude: 30.289, headingDegrees: 0, speedKnots: 0.0)
        ]
        entries.forEach { $0.voyage = voyage; context.insert($0) }

        return voyage
    }

    private static func date(_ cal: Calendar, _ now: Date,
                             daysAgo: Int = 0, daysInFuture: Int = 0,
                             addingHours: Double = 0) -> Date {
        let base = cal.date(byAdding: .day, value: daysInFuture - daysAgo, to: now) ?? now
        return base.addingTimeInterval(addingHours * 3600)
    }

    /// Inserts a single UNRESOLVED MOB point so `MOBEngine` picks it up as the
    /// active incident on launch. Used only by the screenshot/preview harness
    /// (behind the `--seed-mob-active` launch argument) — never in production.
    static func seedActiveMOB(_ context: ModelContext, now: Date = .now) {
        let point = MOBPoint(timestamp: now.addingTimeInterval(-92), // ~1:32 elapsed
                             latitude: 43.288, longitude: 5.343,
                             resolved: false)
        context.insert(point)
        try? context.save()
    }
}
