import Foundation

/// Aggregates a voyage's track into the figures the Statistics screen shows:
/// per-mode distance breakdown (Engine / Sails / Sails & Engine / Idle) and the
/// speed series for the chart.
struct VoyageStatistics {

    struct ModeSlice: Identifiable {
        let id = UUID()
        let mode: PropulsionMode
        let distanceNM: Double
        let fraction: Double        // 0…1 of total
    }

    struct SpeedSample: Identifiable {
        let id = UUID()
        let time: Date
        let speedKn: Double
        let mode: PropulsionMode
    }

    let totalDistanceNM: Double
    let maxSpeedKn: Double
    let avgSpeedKn: Double
    let slices: [ModeSlice]
    let speedSeries: [SpeedSample]

    init(voyage: Voyage) {
        let points = voyage.orderedTrack

        var perMode: [PropulsionMode: Double] = [:]
        var samples: [SpeedSample] = []
        var maxKn = 0.0
        var speedSum = 0.0

        for i in points.indices {
            let p = points[i]
            samples.append(SpeedSample(time: p.timestamp, speedKn: p.speedKnots, mode: p.propulsion))
            maxKn = max(maxKn, p.speedKnots)
            speedSum += p.speedKnots

            if i > 0 {
                let seg = NavigationMath.haversineMeters(points[i - 1].coordinate, p.coordinate)
                perMode[p.propulsion, default: 0] += Units.metersToNM(seg)
            }
        }

        let total = perMode.values.reduce(0, +)
        self.totalDistanceNM = total
        self.maxSpeedKn = maxKn
        self.avgSpeedKn = points.isEmpty ? 0 : speedSum / Double(points.count)
        self.speedSeries = samples

        self.slices = PropulsionMode.allCases.map { mode in
            let d = perMode[mode] ?? 0
            return ModeSlice(mode: mode, distanceNM: d,
                             fraction: total > 0 ? d / total : 0)
        }
    }
}
