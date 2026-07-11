import SwiftUI

/// A full circular "ring" gauge in the Apple-Health style: a thin track ring,
/// a colored progress ring, a centered icon, a big tabular value and a caption.
/// Used for Speed / Progress / Fuel on the Today screen.
struct RingGauge: View {
    @Environment(\.appTheme) private var theme

    let value: Double
    let maxValue: Double
    let unit: String?
    let caption: LocalizedStringKey
    var symbol: String?
    var tint: Color?
    /// Show the value as an integer percentage instead of a decimal.
    var asPercent: Bool = false

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(1, max(0, value / maxValue))
    }

    private var display: String {
        asPercent ? "\(Int((fraction * 100).rounded()))" : value.oneDecimal
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(theme.hairline, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke((tint ?? theme.accent).gradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(tint ?? theme.accent)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(display)
                            .font(AppFont.numeral(26))
                            .foregroundStyle(theme.ink)
                            .monospacedDigit()
                        if let unit {
                            Text(asPercent ? "%" : unit)
                                .font(AppFont.caption)
                                .foregroundStyle(theme.inkSecondary)
                        } else if asPercent {
                            Text("%").font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                        }
                    }
                }
            }
            .frame(width: 108, height: 108)
            Text(caption)
                .font(AppFont.footnote)
                .foregroundStyle(theme.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A compact half-arc gauge (used where a full ring is too big).
struct ArcGauge: View {
    @Environment(\.appTheme) private var theme

    let value: Double
    let maxValue: Double
    let unit: String
    var label: LocalizedStringKey?
    var tint: Color?

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(1, max(0, value / maxValue))
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if let label {
                Text(label).instrumentLabel(theme.inkSecondary)
            }
            ZStack {
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(theme.hairline, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(90))
                Circle()
                    .trim(from: 0.15, to: 0.15 + 0.70 * fraction)
                    .stroke((tint ?? theme.accent).gradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(90))
                VStack(spacing: 0) {
                    Text(value.oneDecimal)
                        .font(AppFont.gaugeNumeral)
                        .foregroundStyle(theme.ink)
                        .monospacedDigit()
                    Text(unit)
                        .font(AppFont.caption)
                        .foregroundStyle(theme.inkSecondary)
                }
            }
            .frame(width: 92, height: 92)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Ring gauges") {
    HStack(spacing: 16) {
        RingGauge(value: 2.8, maxValue: 12, unit: "kn", caption: "Speed",
                  symbol: "gauge.with.dots.needle.bottom.50percent", tint: AppTheme.light.blue)
        RingGauge(value: 62, maxValue: 100, unit: nil, caption: "Progress",
                  symbol: "flag.fill", tint: AppTheme.light.green, asPercent: true)
        RingGauge(value: 68, maxValue: 100, unit: nil, caption: "Fuel",
                  symbol: "fuelpump.fill", tint: AppTheme.light.purple, asPercent: true)
    }
    .padding()
    .environment(\.appTheme, .light)
    .background(AppTheme.light.background)
}
