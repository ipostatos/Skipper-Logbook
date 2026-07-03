import SwiftUI

/// The heading compass at the heart of the dashboard: a rotating tick ring with
/// N/E/S/W cardinals, a fixed lubber index at the top, a boat silhouette, an
/// optional waypoint marker at its relative bearing, and the big heading numeral.
struct CompassDial: View {
    @Environment(\.appTheme) private var theme

    /// Ship's heading in degrees (the ring rotates by −heading so the current
    /// heading sits under the top index).
    let heading: Double
    /// Optional absolute bearing to a waypoint; drawn as a marker on the ring.
    var waypointBearing: Double? = nil
    var showNumeral: Bool = true

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Rotating dial
                Canvas { context, canvasSize in
                    drawDial(&context, size: canvasSize)
                }
                .rotationEffect(.degrees(-heading))

                // Fixed lubber-line index at top
                lubberIndex
                    .offset(y: -size / 2 + 6)

                // Boat silhouette (fixed, pointing up = current heading)
                BoatSilhouette()
                    .fill(theme.accentSoft)
                    .overlay(BoatSilhouette().stroke(theme.accent, lineWidth: 1.5))
                    .frame(width: size * 0.16, height: size * 0.42)

                // Waypoint marker rotates with the ring (relative to heading)
                if let wp = waypointBearing {
                    waypointMarker
                        .offset(y: -size * 0.38)
                        .rotationEffect(.degrees(wp - heading))
                }

                if showNumeral {
                    VStack(spacing: 0) {
                        Spacer()
                        Text("\(Int(NavigationMath.normalizedDegrees(heading)))°")
                            .font(AppFont.headingNumeral)
                            .foregroundStyle(theme.ink)
                            .monospacedDigit()
                        Spacer().frame(height: size * 0.06)
                    }
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Heading")
        .accessibilityValue("\(Int(NavigationMath.normalizedDegrees(heading))) degrees")
    }

    private var lubberIndex: some View {
        Triangle()
            .fill(theme.accent)
            .frame(width: 14, height: 10)
    }

    private var waypointMarker: some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(theme.warning)
            .rotationEffect(.degrees(180))
    }

    private func drawDial(_ context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        let tickOuter = radius - 4

        // Outer ring
        let ring = Path(ellipseIn: CGRect(x: center.x - radius + 2, y: center.y - radius + 2,
                                          width: (radius - 2) * 2, height: (radius - 2) * 2))
        context.stroke(ring, with: .color(theme.hairline), lineWidth: 1)

        // Ticks every 5°, longer + bolder every 30°
        for deg in stride(from: 0, to: 360, by: 5) {
            let major = deg % 30 == 0
            let tickLen: CGFloat = major ? 12 : 6
            let angle = Angle.degrees(Double(deg) - 90).radians
            let p1 = CGPoint(x: center.x + cos(angle) * tickOuter,
                             y: center.y + sin(angle) * tickOuter)
            let p2 = CGPoint(x: center.x + cos(angle) * (tickOuter - tickLen),
                             y: center.y + sin(angle) * (tickOuter - tickLen))
            var tick = Path()
            tick.move(to: p1); tick.addLine(to: p2)
            context.stroke(tick, with: .color(major ? theme.inkSecondary : theme.inkTertiary),
                           lineWidth: major ? 1.4 : 0.8)
        }

        // Cardinal letters
        let cardinals: [(String, Int)] = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
        for (label, deg) in cardinals {
            let angle = Angle.degrees(Double(deg) - 90).radians
            let r = tickOuter - 26
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            let text = Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(deg == 0 ? theme.accent : theme.inkSecondary)
            context.draw(text, at: point)
        }
    }
}

/// A slender boat hull silhouette, pointed at top.
private struct BoatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))                       // bow
        p.addQuadCurve(to: CGPoint(x: w, y: h * 0.5),
                       control: CGPoint(x: w * 0.98, y: h * 0.18))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h),
                       control: CGPoint(x: w * 0.9, y: h * 0.95))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5),
                       control: CGPoint(x: w * 0.1, y: h * 0.95))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0),
                       control: CGPoint(x: w * 0.02, y: h * 0.18))
        p.closeSubpath()
        return p
    }
}

/// An upward-pointing triangle used for the lubber index.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

#Preview("Compass — night") {
    ZStack {
        Color(hex: "0B1626").ignoresSafeArea()
        CompassDial(heading: 196, waypointBearing: 250)
            .frame(width: 260, height: 260)
    }
    .environment(\.appTheme, .night)
}

#Preview("Compass — paper") {
    CompassDial(heading: 196, waypointBearing: 250)
        .frame(width: 260, height: 260)
        .padding()
        .environment(\.appTheme, .paper)
}
