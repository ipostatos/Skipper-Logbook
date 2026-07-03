import Foundation
import AVFoundation
import Observation

/// Records and plays back voice notes with AVFoundation. Exposes live metering
/// (for the waveform) while recording, and playback progress. Audio files are
/// stored under Documents/VoiceNotes.
@Observable
@MainActor
final class AudioRecorderController: NSObject {

    enum Mode { case idle, recording, playing }
    private(set) var mode: Mode = .idle
    private(set) var elapsed: TimeInterval = 0
    /// Rolling normalized levels (0…1) sampled while recording, for the waveform.
    private(set) var levels: [CGFloat] = []
    private(set) var playbackProgress: Double = 0

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?
    private var currentFileName: String?

    static let folderName = "VoiceNotes"

    static var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for fileName: String) -> URL {
        folderURL.appendingPathComponent(fileName)
    }

    // MARK: Recording

    /// Begins recording into a new file. Returns the filename used.
    @discardableResult
    func startRecording(fileName: String) -> Bool {
        stopEverything()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let url = Self.url(for: fileName)
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            self.recorder = recorder
            self.currentFileName = fileName
            self.levels = []
            self.elapsed = 0
            self.mode = .recording
            startMeterTimer()
            return true
        } catch {
            return false
        }
    }

    /// Stops recording. Returns the file name + duration, or nil on failure.
    @discardableResult
    func stopRecording() -> (fileName: String, duration: TimeInterval)? {
        guard mode == .recording, let recorder, let fileName = currentFileName else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        stopMeterTimer()
        self.recorder = nil
        self.mode = .idle
        return (fileName, duration)
    }

    // MARK: Playback

    func play(fileName: String) {
        stopEverything()
        let url = Self.url(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.play()
            self.player = player
            self.mode = .playing
            startPlaybackTimer()
        } catch { }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        stopMeterTimer()
        mode = .idle
        playbackProgress = 0
    }

    // MARK: Timers

    private func startMeterTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.recorder else { return }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)      // dB, ~ −160…0
                let normalized = CGFloat(max(0, (power + 60) / 60))    // clamp to 0…1
                self.levels.append(normalized)
                self.elapsed = recorder.currentTime
            }
        }
    }

    private func startPlaybackTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player, player.duration > 0 else { return }
                self.playbackProgress = player.currentTime / player.duration
            }
        }
    }

    private func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func stopEverything() {
        recorder?.stop(); recorder = nil
        player?.stop(); player = nil
        stopMeterTimer()
        mode = .idle
    }
}

extension AudioRecorderController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopPlayback()
        }
    }
}
