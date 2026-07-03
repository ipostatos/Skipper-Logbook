import AVFoundation
import Photos
import Observation

/// Small façade over the microphone & photo-library permissions used by the
/// Voice Log and Vessel-photo features, surfaced in Settings & Onboarding.
@Observable
@MainActor
final class PermissionsCenter {

    private(set) var microphoneGranted: Bool = false

    init() {
        refreshMicrophone()
    }

    func refreshMicrophone() {
        microphoneGranted = AVAudioApplication.shared.recordPermission == .granted
    }

    func requestMicrophone() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        microphoneGranted = granted
        return granted
    }

    func requestPhotoLibrary() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
}
