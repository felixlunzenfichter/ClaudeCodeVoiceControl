import AVFoundation
import SwiftUI

@Observable
class AudioManager: NSObject {
    var permissionStatus = "Checking..."
    var averageLevel: Float = 0.0
    var isRecording = false
    
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    // Transcription client
    let transcriptionClient = TranscriptionClient()
    private var lastConnectionAttempt = Date.distantPast
    private let connectionCooldown: TimeInterval = 5.0 // 5 seconds between connection attempts
    
    // Auto-disconnect tracking
    private var lastAudioTime = Date()
    private let disconnectDelay: TimeInterval = 1.0 // Disconnect after 1 second of silence
    
    override init() {
        super.init()
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }
    
    func checkAndRequestPermission() {
        Logger.shared.log("Checking microphone permission")
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            permissionStatus = "Granted ✅"
            Logger.shared.log("Permission granted, starting recording")
            startRecording()
        case .denied:
            permissionStatus = "Denied ❌"
        case .restricted:
            permissionStatus = "Restricted ⚠️"
        case .notDetermined:
            permissionStatus = "Requesting..."
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = granted ? "Granted ✅" : "Denied ❌"
                    if granted {
                        self?.startRecording()
                    }
                }
            }
        @unknown default:
            permissionStatus = "Unknown"
        }
    }
    
    private func startRecording() {
        // Use the hardware's native format instead of forcing a specific format
        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        
        Logger.shared.log("Hardware format: \(hardwareFormat.sampleRate) Hz, \(hardwareFormat.channelCount) channels")
        Logger.shared.log("Hardware format description: \(hardwareFormat)")
        
        // For debugging - check input format too
        let inputFormat = inputNode.inputFormat(forBus: 0)
        Logger.shared.log("Input format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channels")
        
        // Install tap with nil format to use the hardware's native format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            Logger.shared.log("Audio engine started successfully")
        } catch {
            Logger.shared.log("Failed to start audio engine: \(error)")
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0.0
        
        // Calculate average of absolute values of samples
        for i in 0..<frameLength {
            let sample = channelData[0][i]
            sum += abs(sample)
        }
        
        let average = sum / Float(frameLength)
        
        DispatchQueue.main.async {
            self.averageLevel = average
        }
        
        // Auto-connect when audio is detected (with cooldown)
        if average > 0 && !transcriptionClient.isConnected {
            let now = Date()
            if now.timeIntervalSince(lastConnectionAttempt) >= connectionCooldown {
                Logger.shared.log("Audio detected (level: \(average)), connecting to transcription service")
                lastConnectionAttempt = now
                transcriptionClient.connect()
            }
        }
        
        // Track audio activity
        if average > 0 {
            lastAudioTime = Date()
        }
        
        // Auto-disconnect when no audio for a while (microphone muted)
        if average == 0 && transcriptionClient.isConnected {
            let timeSinceLastAudio = Date().timeIntervalSince(lastAudioTime)
            if timeSinceLastAudio >= disconnectDelay {
                Logger.shared.log("No audio for \(disconnectDelay) seconds, disconnecting to save costs")
                transcriptionClient.disconnect()
            }
        }
        
        // Send audio to transcription service
        if transcriptionClient.isConnected {
            // Convert to LINEAR16 format (backend will resample)
            if let audioData = convertToLinear16(buffer) {
                transcriptionClient.sendAudioData(audioData)
                // Don't log audio sends - too noisy
            }
        } else if average > 0 {
            Logger.shared.log("Audio level \(average) but not connected yet")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        transcriptionClient.disconnect()
    }
    // Convert audio buffer to LINEAR16 format for Google Speech
    private func convertToLinear16(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.floatChannelData else { return nil }
        
        let frameCount = Int(buffer.frameLength)
        var data = Data()
        
        // Convert Float32 samples to Int16
        for frame in 0..<frameCount {
            let sample = channelData[0][frame]
            // Clamp to [-1, 1] range and convert to Int16
            let int16Sample = Int16(max(-32768, min(32767, sample * 32767)))
            
            // Append as little-endian bytes
            withUnsafeBytes(of: int16Sample.littleEndian) { bytes in
                data.append(contentsOf: bytes)
            }
        }
        
        return data
    }
}