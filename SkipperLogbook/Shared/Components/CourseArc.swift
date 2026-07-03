import SwiftUI

/// The hero course indicator on Today: a wide top arc with a gradient sweep, a
/// fixed lubber triangle at the top, small S / W end labels, and the big course
/// numeral centered below. Calmer than a full compass — matches the mockup.
struct CourseArc: View {
    @Environment(\.appTheme) private var theme
    let course: Double
    var leftLabel: String = "S"
    var rightLabel: String = "W"

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width
                    let r = w * 0.42
                    let center = CGPoint(x: w / 2, y: r + 14)

                    // Track arc (top ~200°)
                    ArcShape(center: center, radius: r, start: 160, end: 380)
                        .stroke(theme.hairline, style: StrokeStyle(lineWidth: 6, lineCap: .round))

                    // Gradient sweep
                    ArcShape(center: center, radius: r, start: 160, end: 380)
                        .stroke(
                            AngularGradient(colors: [theme.cyan, theme.blue, theme.purple],
                                            center: .center, angle: .degrees(90)),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .opacity(0.9)

                    // Tick marks along the arc
                    ForEach(Array(stride(from: 165.0, through: 375.0, by: 15.0)), id: \.self) { deg in
                        tick(center: center, radius: r, degrees: deg)
                    }

                    // Lubber triangle at top
                    Triangle()
                        .fill(theme.blue)
                        .frame(width: 16, height: 12)
                        .position(x: center.x, y: center.y - r - 2)

                    // End labels
                    Text(leftLabel).font(AppFont.caption).foregroundStyle(theme.inkTertiary)
                        .position(pointOn(center: center, radius: r + 20, degrees: 162))
                    Text(rightLabel).font(AppFont.caption).foregroundStyle(theme.inkTertiary)
                        .position(pointOn(center: center, radius: r + 20, degrees: 378))
                }
                VStack(spacing: -4) {
                    Text("\(Int(NavigationMath.normalizedDegrees(course)))°")
                        .font(AppFont.numeral(58))
                        .foregroundStyle(theme.ink)
                        .monospacedDigit()
                    Text("course.label")
                        .font(AppFont.subheadline)
                        .foregroundStyle(theme.inkSecondary)
                }
                .offset(y: 24)
            }
        }
        .frame(height: 190)
        .accessibilityLabel("Course over ground")
        .accessibilityValue("\(Int(NavigationMath.normalizedDegrees(course))) degrees")
    }

    private func tick(center: CGPoint, radius: CGFloat, degrees: Double) -> some View {
        let outer = pointOn(center: center, radius: radius - 12, degrees: degrees)
        let inner = pointOn(center: center, radius: radius - 20, degrees: degrees)
        return Path { p in p.move(to: outer); p.addLine(to: inner) }
            .stroke(theme.inkTertiary.opacity(0.5), lineWidth: 1)
    }

    private func pointOn(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let rad = degrees * .pi / 180
        return CGPoint(x: center.x + cos(rad) * radius, y: center.y + sin(rad) * radius)
    }
}

/// An open arc between two angles (degrees, measured like a unit circle).
struct ArcShape: Shape {
    let center: CGPoint
    let radius: CGFloat
    let start: Double
    let end: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        return p
    }
}

#Preview("Course arc") {
    CourseArc(course: 196)
        .padding()
        .environment(\.appTheme, .light)
        .background(AppTheme.light.background)
}
