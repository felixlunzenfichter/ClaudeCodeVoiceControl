//
//  ClaudeCodeVoiceControlTests.swift
//  ClaudeCodeVoiceControlTests
//
//  Created by Felix Lunzenfichter on 6/11/25.
//

import Testing
import AVFoundation

struct ClaudeCodeVoiceControlTests {

    @Test func testMicrophonePermission() async throws {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case .granted:
            print("✅ Microphone permission: GRANTED")
            // Test succeeds if permission is granted
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
