import SwiftUI

/// The screen wordmark used at the top of primary tabs: a small sailboat mark,
/// "Skipper Logbook", the BETA pill, and an optional MOB quick-trigger + menu.
struct AppHeader: View {
    @Environment(\.appTheme) private var theme

    var showsMOB: Bool = true
    var onMOB: (() -> Void)?
    var trailing: AnyView?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            SailboatMark()
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: -2) {
                HStack(spacing: 6) {
                    Text("Skipper")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                    BetaBadge()
                }
                Text("Logbook")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(theme.inkSecondary)
            }
            .foregroundStyle(theme.ink)

            Spacer()

            if showsMOB, let onMOB {
                Button(action: onMOB) {
                    Text("MOB")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(theme.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(theme.danger))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Man overboard")
            }
            if let trailing { trailing }
        }
    }
}

/// A compact vector sailboat used as the in-app logo mark (mirrors the app icon).
struct SailboatMark: View {
    @Environment(\.appTheme) private var theme
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Main sail
                Path { p in
                    p.move(to: CGPoint(x: s * 0.55, y: s * 0.1))
                    p.addLine(to: CGPoint(x: s * 0.85, y: s * 0.62))
                    p.addLine(to: CGPoint(x: s * 0.55, y: s * 0.62))
                    p.closeSubpath()
                }
                .fill(theme.accent)
                // Fore sail
                Path { p in
                    p.move(to: CGPoint(x: s * 0.5, y: s * 0.22))
                    p.addLine(to: CGPoint(x: s * 0.5, y: s * 0.62))
                    p.addLine(to: CGPoint(x: s * 0.28, y: s * 0.62))
                    p.closeSubpath()
                }
                .fill(theme.accent.opacity(0.85))
                // Hull
                Path { p in
                    p.move(to: CGPoint(x: s * 0.2, y: s * 0.68))
                    p.addLine(to: CGPoint(x: s * 0.86, y: s * 0.68))
                    p.addLine(to: CGPoint(x: s * 0.72, y: s * 0.82))
                    p.addLine(to: CGPoint(x: s * 0.32, y: s * 0.82))
                    p.closeSubpath()
                }
                .fill(theme.accent)
            }
        }
    }
}

#Preview("Header") {
    AppHeader(onMOB: {})
        .padding()
        .environment(\.appTheme, .paper)
}
