import AVFoundation
import SwiftUI

@Observable
class AudioManager: NSObject {
    var permissionStatus = "Checking..."
    var averageLevel: Float = 0.0
    var isRecording = false
    
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    override init() {
        super.init()
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }
    
    func checkAndRequestPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            permissionStatus = "Granted ✅"
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
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
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
    }
    
    func stopRecording() {
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
    }
}