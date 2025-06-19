import Foundation
import WhisperKit

enum TranscriptionError: Error {
    case whisperKitNotReady
}

class TranscriptionService {
    
    private var whisperKit: WhisperKit?
    
    init() {
        Task {
            await setupWhisperKit()
        }
    }
    
    private func setupWhisperKit() async {
        do {
            print("🔄 Starting WhisperKit initialization...")
            whisperKit = try await WhisperKit()
            print("✅ WhisperKit initialized successfully")
        } catch {
            print("❌ Failed to initialize WhisperKit: \(error)")
        }
    }
    
    func transcribe(_ audioData: Data) async throws -> String {
        var attempts = 0
        while whisperKit == nil && attempts < 10 {
            try await Task.sleep(for: .seconds(1))
            attempts += 1
        }
        
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.whisperKitNotReady
        }
        
        let tempURL = createTempWAVFile(from: audioData)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        print("🔊 Transcribing audio file: \(tempURL.path)")
        
        let results = try await whisperKit.transcribe(audioPath: tempURL.path)
        let transcriptionText = results.first?.text ?? ""
        
        print("📝 Transcribed: '\(transcriptionText)' (results count: \(results.count))")
        
        return transcriptionText
    }
    
    private func createTempWAVFile(from audioData: Data) -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        
        var wavData = Data()
        
        let sampleRate: UInt32 = 48000
        let channels: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = channels * (bitsPerSample / 8)
        let bytesPerSecond = sampleRate * UInt32(bytesPerSample)
        
        wavData.append("RIFF".data(using: .ascii)!)
        var fileSize = UInt32(36 + audioData.count).littleEndian
        wavData.append(Data(bytes: &fileSize, count: 4))
        wavData.append("WAVE".data(using: .ascii)!)
        
        wavData.append("fmt ".data(using: .ascii)!)
        var formatChunkSize = UInt32(16).littleEndian
        wavData.append(Data(bytes: &formatChunkSize, count: 4))
        var audioFormat = UInt16(1).littleEndian
        wavData.append(Data(bytes: &audioFormat, count: 2))
        var channelsLE = channels.littleEndian
        wavData.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE = sampleRate.littleEndian
        wavData.append(Data(bytes: &sampleRateLE, count: 4))
        var bytesPerSecondLE = bytesPerSecond.littleEndian
        wavData.append(Data(bytes: &bytesPerSecondLE, count: 4))
        var bytesPerSampleLE = bytesPerSample.littleEndian
        wavData.append(Data(bytes: &bytesPerSampleLE, count: 2))
        var bitsPerSampleLE = bitsPerSample.littleEndian
        wavData.append(Data(bytes: &bitsPerSampleLE, count: 2))
        
        wavData.append("data".data(using: .ascii)!)
        var dataSize = UInt32(audioData.count).littleEndian
        wavData.append(Data(bytes: &dataSize, count: 4))
        wavData.append(audioData)
        
        try? wavData.write(to: tempURL)
        return tempURL
    }
}