import Foundation
import SwiftUI

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcriptions: [String] = []
    @Published var isRecording = false
    @Published var status = "Initializing WhisperKit..."
    @Published var isProcessing = false
    
    private let audioManager = AudioManager()
    private let transcriptionService = TranscriptionService()
    private var processingQueue = [Data]()
    
    init() {
        setupAudioProcessing()
        checkWhisperKitStatus()
    }
    
    private func setupAudioProcessing() {
        audioManager.onAudioChunk = { [weak self] audioData in
            Task { [weak self] in
                await self?.addToQueue(audioData)
            }
        }
    }
    
    private func checkWhisperKitStatus() {
        Task {
            await MainActor.run {
                self.status = "Initializing WhisperKit (30-60s)..."
            }
            
            // Give WhisperKit time to initialize
            try? await Task.sleep(for: .seconds(35))
            
            await MainActor.run {
                self.status = "Ready"
            }
        }
    }
    
    private func addToQueue(_ audioData: Data) async {
        processingQueue.append(audioData)
        
        if !isProcessing {
            await processQueue()
        }
    }
    
    private func processQueue() async {
        guard !processingQueue.isEmpty else { return }
        
        await MainActor.run {
            self.isProcessing = true
            self.status = "Processing audio..."
        }
        
        while !processingQueue.isEmpty {
            let audioData = processingQueue.removeFirst()
            await processAudioChunk(audioData)
        }
        
        await MainActor.run {
            self.isProcessing = false
            self.status = "Listening..."
        }
    }
    
    private func processAudioChunk(_ audioData: Data) async {
        do {
            let transcription = try await transcriptionService.transcribe(audioData)
            if !transcription.isEmpty {
                await MainActor.run {
                    self.transcriptions.insert(transcription, at: 0)
                    self.status = "Transcribed: \(transcription)"
                }
            }
        } catch {
            await MainActor.run {
                self.status = "Error: \(error.localizedDescription)"
            }
            print("Transcription error: \(error)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            audioManager.stopRecording()
            isRecording = false
            status = "Ready"
        } else {
            audioManager.startRecording()
            isRecording = true
            status = "Listening..."
        }
    }
}