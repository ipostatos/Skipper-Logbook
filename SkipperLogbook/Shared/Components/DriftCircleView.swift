import SwiftUI

/// The anchor-watch drift diagram: the anchor at center, the alarm-radius circle,
/// the boat's recent trail, and the boat's current position/heading. All inputs
/// are in metres relative to the anchor (East = +x, North = +y).
struct DriftCircleView: View {
    @Environment(\.appTheme) private var theme

    /// Alarm radius in metres.
    let radiusMeters: Double
    /// Boat offset from anchor in metres (east, north).
    let boatOffset: CGPoint
    /// Recent trail as metre offsets from the anchor.
    let trail: [CGPoint]
    /// Boat heading in degrees, for the hull orientation.
    var heading: Double = 0
    var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            // Scale so the alarm circle fills ~70% of the view; clamp for drift beyond radius.
            let maxMeters = max(radiusMeters * 1.25, hypot(boatOffset.x, boatOffset.y) * 1.1, 1)
            let scale = (side * 0.42) / maxMeters

            ZStack {
                // Alarm radius circle
                let r = radiusMeters * scale
                Circle()
                    .fill((isDragging ? theme.danger : theme.success).opacity(0.10))
                    .frame(width: r * 2, height: r * 2)
                    .position(center)
                Circle()
                    .strokeBorder(isDragging ? theme.danger : theme.success,
                                  style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: r * 2, height: r * 2)
                    .position(center)

                // Trail
                Path { path in
                    for (i, p) in trail.enumerated() {
                        let pt = point(p, center: center, scale: scale)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                }
                .stroke(theme.accent.opacity(0.5), lineWidth: 1.5)

                // Anchor at center
                Image(systemName: "anchor.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.inkSecondary)
                    .position(center)

                // Rode line anchor → boat
                let boatPt = point(boatOffset, center: center, scale: scale)
                Path { p in p.move(to: center); p.addLine(to: boatPt) }
                    .stroke(theme.inkTertiary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                // Boat
                Image(systemName: "sailboat.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isDragging ? theme.danger : theme.sail)
                    .rotationEffect(.degrees(heading))
                    .position(boatPt)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall, style: .continuous))
    }

    /// Convert a metre offset (east, north) to a view point (y inverted).
    private func point(_ meters: CGPoint, center: CGPoint, scale: Double) -> CGPoint {
        CGPoint(x: center.x + meters.x * scale,
                y: center.y - meters.y * scale)
    }
}

#Preview("Drift circle") {
    DriftCircleView(radiusMeters: 15,
                    boatOffset: CGPoint(x: 6, y: -4),
                    trail: [CGPoint(x: 0, y: 0), CGPoint(x: 3, y: -1), CGPoint(x: 6, y: -4)],
                    heading: 40)
        .frame(height: 260)
        .padding()
        .environment(\.appTheme, .night)
        .background(Color(hex: "0B1626"))
}
