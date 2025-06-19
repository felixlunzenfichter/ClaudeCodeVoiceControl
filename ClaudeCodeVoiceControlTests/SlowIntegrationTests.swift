import Testing
import AVFoundation
import Foundation
@testable import ClaudeCodeVoiceControl

struct SlowIntegrationTests {
    
    @Test func testRealTimeTranscriptionService() async throws {
        let service = TranscriptionService()
        
        print("⏳ Waiting for WhisperKit to initialize...")
        try await Task.sleep(for: .seconds(10))
        
        print("📁 Loading test audio...")
        let audioData = try await loadFirstTenSecondsFromBundle()
        print("🎵 Processing audio: \(audioData.count) bytes (~10 seconds)")
        
        let transcription = try await service.transcribe(audioData)
        
        print("📝 Received transcription: '\(transcription)'")
        
        #expect(!transcription.isEmpty, "Should receive transcription from test audio file")
        
        let lowercasedTranscription = transcription.lowercased()
        print("🔍 Transcription: '\(lowercasedTranscription)'")
        
        #expect(transcription.contains("This is my voice on the left."), "Should transcribe 'This is my voice on the left.' from test audio")
        
        print("✅ Transcription test passed - WhisperKit successfully transcribed test audio")
    }
    
    private func loadFirstTenSecondsFromBundle() async throws -> Data {
        class BundleClass {}
        let testBundle = Bundle(for: BundleClass.self)
        
        guard let testAudioURL = testBundle.url(forResource: "test_audio", withExtension: "wav") else {
            print("❌ Could not find test_audio.wav in test bundle")
            print("📦 Test bundle path: \(testBundle.bundlePath)")
            
            if let resourcePath = testBundle.resourcePath {
                print("📂 Resource path: \(resourcePath)")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                    print("📂 Resource contents: \(contents)")
                }
            }
            
            throw TestAudioError.fileNotFound(path: "test_audio.wav in test bundle")
        }
        
        print("📂 Loading test audio from: \(testAudioURL.path)")
        
        let fileHandle = try FileHandle(forReadingFrom: testAudioURL)
        defer { fileHandle.closeFile() }
        
        fileHandle.seek(toFileOffset: 44)
        
        let sampleRate: Int = 48000
        let channels: Int = 2
        let bytesPerSample: Int = 2
        let secondsToRead: Int = 10
        let bytesToRead = sampleRate * channels * bytesPerSample * secondsToRead
        
        let audioData = fileHandle.readData(ofLength: bytesToRead)
        
        print("📊 Read \(audioData.count) bytes of audio data")
        return audioData
    }
}

enum TestAudioError: Error {
    case fileNotFound(path: String)
}