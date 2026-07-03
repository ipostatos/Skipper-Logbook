import SwiftUI

/// A tiny smoothed area+line sparkline used at the bottom of the Speed /
/// To-waypoint cards on Today. Purely decorative-but-real: it reflects recent
/// samples (0…1 normalized) with a trailing dot.
struct Sparkline: View {
    @Environment(\.appTheme) private var theme
    let samples: [CGFloat]      // normalized 0…1
    var tint: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let color = tint ?? theme.accent
            let pts = points(in: geo.size)
            ZStack {
                // Fill under the line
                area(pts, in: geo.size)
                    .fill(LinearGradient(colors: [color.opacity(0.22), color.opacity(0.0)],
                                         startPoint: .top, endPoint: .bottom))
                // The line
                line(pts)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                // Trailing dot
                if let last = pts.last {
                    Circle().fill(color).frame(width: 6, height: 6).position(last)
                }
            }
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard samples.count > 1 else {
            return [CGPoint(x: 0, y: size.height / 2), CGPoint(x: size.width, y: size.height / 2)]
        }
        let stepX = size.width / CGFloat(samples.count - 1)
        return samples.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * stepX, y: size.height * (1 - max(0, min(1, v))))
        }
    }

    private func line(_ pts: [CGPoint]) -> Path {
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for pt in pts.dropFirst() { p.addLine(to: pt) }
        return p
    }

    private func area(_ pts: [CGPoint], in size: CGSize) -> Path {
        var p = line(pts)
        guard let first = pts.first, let last = pts.last else { return p }
        p.addLine(to: CGPoint(x: last.x, y: size.height))
        p.addLine(to: CGPoint(x: first.x, y: size.height))
        p.closeSubpath()
        return p
    }
}

#Preview("Sparkline") {
    Sparkline(samples: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.55, 0.9], tint: AppTheme.light.blue)
        .frame(height: 40)
        .padding()
        .environment(\.appTheme, .light)
}
