import SwiftUI
import SwiftData

/// Audio Log — capture voice notes tied to your position (Voice-Memos-style,
/// maritime). Reached from the Log tab. A big mic button + live waveform, the
/// current fix, quick tags, and the recent-notes list. Screen accent: purple.
struct AudioLogView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(PermissionsCenter.self) private var permissions

    @State private var audio = AudioRecorderController()
    @State private var micDenied = false
    @State private var selectedTags: Set<VoiceTag> = []

    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                recorderCard
                recentSection
                infoRow
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .background(theme.background)
        .navigationTitle("voice.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.close") { dismiss() }
            }
        }
        .alert("voice.mic_denied_title", isPresented: $micDenied) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("voice.mic_denied_message") }
    }

    private var recorderCard: some View {
        Card {
            VStack(spacing: Spacing.md) {
                Button(action: toggleRecording) {
                    ZStack {
                        if audio.mode == .recording {
                            Circle().fill(theme.danger.opacity(0.15)).frame(width: 96, height: 96)
                        }
                        Circle().fill(audio.mode == .recording ? theme.danger : theme.purple)
                            .frame(width: 72, height: 72)
                        Image(systemName: audio.mode == .recording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 26, weight: .semibold)).foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                WaveformView(samples: audio.mode == .recording ? audio.levels : placeholderSamples,
                             isActive: audio.mode == .recording)
                    .frame(height: 48)

                Text(audio.mode == .recording ? audio.elapsed.stopwatchMMSS : "00:00")
                    .font(AppFont.numeral(30)).foregroundStyle(theme.ink).monospacedDigit()
                Text(audio.mode == .recording ? "voice.recording" : "voice.tap_record")
                    .font(AppFont.footnote).foregroundStyle(theme.inkSecondary)

                if let coord = location.currentCoordinate {
                    Text(CoordinateFormatting.string(coord))
                        .font(AppFont.mono(.footnote)).foregroundStyle(theme.inkSecondary)
                }

                tagRow
            }
        }
    }

    /// Weather / Engine / Sails / Crew / Issue — pick before or during the
    /// recording; saved onto the note.
    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(VoiceTag.allCases) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    private func tagChip(_ tag: VoiceTag) -> some View {
        let isOn = selectedTags.contains(tag)
        return Button {
            if isOn { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tag.symbol).font(.system(size: 11, weight: .semibold))
                Text(tag.titleKey).font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isOn ? .white : theme.inkSecondary)
            .background(Capsule().fill(isOn ? theme.purple : theme.background))
            .overlay(Capsule().strokeBorder(isOn ? .clear : theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader("voice.recent")
            if notes.isEmpty {
                EmptyStateView(symbol: "waveform", title: "voice.empty_title", message: "voice.empty_message")
            } else {
                Card(padding: Spacing.xxs) {
                    VStack(spacing: 0) {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { i, note in
                            AudioNoteRow(note: note)
                            if i < notes.count - 1 { Divider().overlay(theme.hairline) }
                        }
                    }
                }
            }
        }
    }

    private var infoRow: some View {
        HStack(spacing: Spacing.sm) {
            infoTile("location", "voice.info_position", theme.blue)
            // Transcription isn't implemented yet — say so, don't imply it.
            infoTile("waveform", "voice.info_transcribe", theme.purple, comingSoon: true)
        }
    }

    private func infoTile(_ symbol: String, _ text: LocalizedStringKey, _ color: Color,
                          comingSoon: Bool = false) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: symbol).foregroundStyle(color)
                    if comingSoon {
                        Spacer(minLength: 0)
                        ComingSoonBadge().padding(-8)
                    }
                }
                Text(text).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Actions

    private func toggleRecording() {
        if audio.mode == .recording {
            finishRecording()
        } else {
            Task { await beginRecording() }
        }
    }

    private func beginRecording() async {
        permissions.refreshMicrophone()
        if !permissions.microphoneGranted {
            let granted = await permissions.requestMicrophone()
            if !granted { micDenied = true; return }
        }
        _ = audio.startRecording(fileName: "vn_\(UUID().uuidString).m4a")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func finishRecording() {
        guard let result = audio.stopRecording() else { return }
        let coord = location.currentCoordinate
        let note = VoiceNote(title: String(localized: "voice.default_title") + " · " + Date.now.hourMinute(),
                             duration: result.duration, fileName: result.fileName,
                             latitude: coord?.latitude, longitude: coord?.longitude,
                             speedKnots: coord != nil ? Units.mpsToKnots(location.speedMps) : nil,
                             // Course over ground, not effectiveHeading — heading
                             // is where the bow points, not where the boat goes.
                             courseDegrees: coord != nil ? location.courseDegrees : nil,
                             tags: VoiceTag.allCases.filter { selectedTags.contains($0) })
        note.voyage = recorder.activeVoyage
        context.insert(note)
        try? context.save()
        selectedTags = []
    }

    private var placeholderSamples: [CGFloat] {
        (0..<60).map { i in 0.2 + 0.15 * CGFloat(abs(sin(Double(i) / 4))) }
    }
}

/// A recent voice-note row with inline play/stop, title, coords, waveform,
/// duration. Long-press to delete (rows live in ScrollView cards, so the
/// List-only swipe actions are not available here).
struct AudioNoteRow: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    let note: VoiceNote
    @State private var audio = AudioRecorderController()
    @State private var isPlaying = false
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                if isPlaying {
                    audio.stopPlayback(); isPlaying = false
                } else {
                    audio.play(fileName: note.fileName); isPlaying = true
                }
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 30)).foregroundStyle(theme.purple)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title).font(AppFont.subheadline).foregroundStyle(theme.ink).lineLimit(1)
                if let lat = note.latitude, let lon = note.longitude {
                    Text(CoordinateFormatting.string(GeoCoordinate(latitude: lat, longitude: lon)))
                        .font(AppFont.mono(.caption2)).foregroundStyle(theme.inkTertiary)
                } else {
                    Text(note.createdAt.shortDate()).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                }
                if !note.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(note.tags) { tag in
                            Image(systemName: tag.symbol)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.purple)
                        }
                    }
                }
            }
            Spacer()
            Text(note.duration.stopwatchMMSS)
                .font(AppFont.mono(.footnote)).foregroundStyle(theme.inkSecondary)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
        .contentShape(Rectangle())
        .onChange(of: audio.mode) { _, mode in if mode == .idle { isPlaying = false } }
        .contextMenu {
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("voice.delete", systemImage: "trash")
            }
        }
        .confirmationDialog("voice.delete_confirm", isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("voice.delete", role: .destructive) { deleteNote() }
            Button("common.cancel", role: .cancel) {}
        }
    }

    private func deleteNote() {
        if isPlaying { audio.stopPlayback(); isPlaying = false }
        note.deleteAudioFile()               // cascade deletes rows, not files
        context.delete(note)
        try? context.save()
    }
}

#Preview("Audio log") {
    NavigationStack {
        AudioLogView()
            .environment(\.appTheme, .light)
            .environment(LocationManager())
            .environment(VoyageRecorder(context: PreviewData.container.mainContext))
            .environment(PermissionsCenter())
            .modelContainer(PreviewData.container)
    }
}
