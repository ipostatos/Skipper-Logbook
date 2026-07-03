import SwiftUI
import Observation

/// Computes the dashboard's live instrument readouts from location + the active
/// voyage. A lightweight value type built on each render from the environment
/// objects (no independent lifecycle needed).
struct DashboardReadout {
    let headingDegrees: Double
    let speedKn: Double
    let toWaypointSpeedKn: Double
    let coordinate: GeoCoordinate?
    let waypointBearing: Double?

    let loggedDistanceNM: Double
    let timeUnderway: TimeInterval
    let remainingDistanceNM: Double?
    let avgSpeedKn: Double
    let engineHours: Double
    let fuelRemainingL: Double?
    let etaSeconds: Double?

    static func make(location: LocationManager,
                     recorder: VoyageRecorder,
                     vesselFuelCapacity: Double?) -> DashboardReadout {
        let coord = location.currentCoordinate
        let speed = location.speedMps
        let voyage = recorder.activeVoyage

        let remaining = recorder.remainingDistanceMeters(from: coord)
        let bearing = recorder.bearingToDestination(from: coord)

        let fuelRemaining: Double?
        if let cap = vesselFuelCapacity, let used = voyage?.fuelUsedLiters {
            fuelRemaining = max(0, cap - used)
        } else {
            fuelRemaining = vesselFuelCapacity
        }

        return DashboardReadout(
            headingDegrees: location.effectiveHeading,
            speedKn: Units.mpsToKnots(speed),
            toWaypointSpeedKn: Units.mpsToKnots(speed),   // VMG approximation for BETA
            coordinate: coord,
            waypointBearing: bearing,
            loggedDistanceNM: voyage?.distanceNM ?? 0,
            timeUnderway: voyage?.elapsed ?? 0,
            remainingDistanceNM: remaining.map(Units.metersToNM),
            avgSpeedKn: voyage?.averageSpeedKn ?? 0,
            engineHours: voyage?.engineHours ?? 0,
            fuelRemainingL: fuelRemaining,
            etaSeconds: recorder.etaSeconds(from: coord, speedMps: speed)
        )
    }
}
