import Testing
import AVFoundation
@testable import ClaudeCodeVoiceControl

struct SlowIntegrationTests {
    
    @Test func testRealTimeTranscriptionService() async throws {
        let service = TranscriptionService()
        
        print("⏳ Waiting for WhisperKit to initialize...")
        try await Task.sleep(for: .seconds(10))
        
        print("📁 Loading test audio...")
        let audioData = try await loadFirstFiveSeconds()
        print("🎵 Processing audio: \(audioData.count) bytes (~5 seconds)")
        
        let transcription = try await service.transcribe(audioData)
        
        print("📝 Received transcription: '\(transcription)'")
        
        #expect(!transcription.isEmpty, "Should receive transcription from test audio file")
        
        let lowercasedTranscription = transcription.lowercased()
        print("🔍 Transcription: '\(lowercasedTranscription)'")
        
        #expect(transcription.contains("This is my voice on the left."), "Should transcribe 'This is my voice on the left.' from test audio")
        
        print("✅ Transcription test passed - WhisperKit successfully transcribed test audio")
    }
    
    private func loadFirstFiveSeconds() async throws -> Data {
        for bundle in Bundle.allBundles {
            if let audioURL = bundle.url(forResource: "test_audio", withExtension: "wav") {
                print("Found audio file in bundle: \(bundle.bundleURL.lastPathComponent)")
                
                let audioData = try Data(contentsOf: audioURL)
                print("Total audio file: \(audioData.count) bytes")
                
                let fiveSecondsBytes = 960000
                let endIndex = min(fiveSecondsBytes, audioData.count)
                let firstFiveSeconds = audioData.subdata(in: 0..<endIndex)
                
                print("Extracted first 5 seconds: \(firstFiveSeconds.count) bytes")
                return firstFiveSeconds
            }
        }
        
        throw IntegrationTestError.audioFileNotFound
    }
}

enum IntegrationTestError: Error {
    case audioFileNotFound
}