import Testing
import AVFoundation
@testable import ClaudeCodeVoiceControl

struct ClaudeCodeVoiceControlTests {

    @Test func testMicrophonePermission() async throws {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case .granted:
            print("✅ Microphone permission: GRANTED")
        case .denied:
            print("❌ Microphone permission: DENIED")
            throw TestError.microphonePermissionDenied
        case .undetermined:
            print("⚠️ Microphone permission: UNDETERMINED")
            throw TestError.microphonePermissionUndetermined
        @unknown default:
            print("❓ Microphone permission: UNKNOWN")
            throw TestError.microphonePermissionUnknown
        }
    }
}

enum TestError: Error {
    case microphonePermissionDenied
    case microphonePermissionUndetermined
    case microphonePermissionUnknown
}
