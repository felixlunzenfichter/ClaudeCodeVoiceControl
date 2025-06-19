import Foundation
import SwiftUI

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcriptions: [String] = []
    @Published var isRecording = false
    
    private let audioManager = AudioManager()
    private let transcriptionService = TranscriptionService()
    
    init() {
        setupAudioProcessing()
    }
    
    private func setupAudioProcessing() {
        audioManager.onAudioChunk = { [weak self] audioData in
            Task { [weak self] in
                await self?.processAudioChunk(audioData)
            }
        }
    }
    
    private func processAudioChunk(_ audioData: Data) async {
        do {
            let transcription = try await transcriptionService.transcribe(audioData)
            if !transcription.isEmpty {
                await MainActor.run {
                    self.transcriptions.insert(transcription, at: 0)
                }
            }
        } catch {
            print("Transcription error: \(error)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            audioManager.stopRecording()
            isRecording = false
        } else {
            audioManager.startRecording()
            isRecording = true
        }
    }
}