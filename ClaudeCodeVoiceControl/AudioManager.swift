import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    
    var onAudioChunk: ((Data) -> Void)?
    
    private var audioBuffer = Data()
    private var chunkTimer: Timer?
    
    private let sampleRate: Double = 48000
    private let channels: UInt32 = 1
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        )!
        
        audioFormat = recordingFormat
        audioBuffer = Data()
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            startChunkTimer()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        chunkTimer?.invalidate()
        chunkTimer = nil
        
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        audioEngine = nil
        inputNode = nil
        
        isRecording = false
        audioBuffer = Data()
    }
    
    private func startChunkTimer() {
        chunkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.deliverChunk()
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let int16Buffer = UnsafeMutablePointer<Int16>.allocate(capacity: frameLength)
        defer { int16Buffer.deallocate() }
        
        for i in 0..<frameLength {
            let sample = channelData[i]
            let clampedSample = max(-1.0, min(1.0, sample))
            int16Buffer[i] = Int16(clampedSample * 32767)
        }
        
        let data = Data(bytes: int16Buffer, count: frameLength * MemoryLayout<Int16>.size)
        audioBuffer.append(data)
    }
    
    private func deliverChunk() {
        guard !audioBuffer.isEmpty else { return }
        
        let chunk = audioBuffer
        audioBuffer = Data()
        
        onAudioChunk?(chunk)
    }
}