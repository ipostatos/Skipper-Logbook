import SwiftUI

/// A simple audio-level waveform for the Voice Log: a row of vertical bars whose
/// heights come from normalized samples (0…1). Used live while recording and
/// statically for a recorded note's envelope.
struct WaveformView: View {
    @Environment(\.appTheme) private var theme

    /// Normalized amplitudes, 0…1. When recording, append new samples over time.
    let samples: [CGFloat]
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2
    var isActive: Bool = false

    var body: some View {
        GeometryReader { geo in
            let count = max(1, Int(geo.size.width / (barWidth + spacing)))
            let visible = Array(samples.suffix(count))
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    let amp = i < visible.count ? visible[i] : 0.04
                    Capsule()
                        .fill(isActive ? theme.accent : theme.inkSecondary)
                        .frame(width: barWidth,
                               height: max(3, amp * geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }
}

#Preview("Waveform") {
    WaveformView(samples: (0..<80).map { _ in CGFloat.random(in: 0.1...1) }, isActive: true)
        .frame(height: 60)
        .padding()
        .environment(\.appTheme, .paper)
}
