import Foundation
import AVFoundation

@Observable
class TranscriptionClient: NSObject {
    // WebSocket connection
    private var webSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    // Connection state
    var isConnected = false
    var connectionStatus = "Disconnected"
    private var isIntentionalDisconnect = false
    
    // Transcription results
    var transcriptionText = ""      // All finalized text
    var currentUtterance = ""       // Current utterance being spoken
    var interimText = ""           // Current interim text (not yet final)
    
    // Backend URL from configuration
    private let backendURL = Configuration.backendURL
    
    func connect() {
        Logger.shared.log("Connecting to: \(backendURL)")
        guard let url = URL(string: backendURL) else {
            connectionStatus = "Invalid URL"
            return
        }
        
        isIntentionalDisconnect = false
        connectionStatus = "Connecting..."
        Logger.shared.log("WebSocket created, status: Connecting...")
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // Start receiving messages
        receiveMessage()
        
        // Wait a moment for connection to establish, then send start message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let startMessage = [
                "type": "start",
                "languageCode": "en-US"
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: startMessage) {
                self?.webSocket?.send(.data(data)) { error in
                    if let error = error {
                        self?.connectionStatus = "Error: \(error.localizedDescription)"
                        Logger.shared.log("Connection error: \(error.localizedDescription)")
                    } else {
                        self?.isConnected = true
                        self?.connectionStatus = "Connected"
                        Logger.shared.log("Successfully connected to backend")
                        Logger.shared.log("Sent start message to begin speech recognition")
                    }
                }
            }
        }
    }
    
    func disconnect() {
        // Send stop message
        let stopMessage = ["type": "stop"]
        if let data = try? JSONSerialization.data(withJSONObject: stopMessage) {
            webSocket?.send(.data(data)) { _ in }
        }
        
        isIntentionalDisconnect = true
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    func sendAudioData(_ audioData: Data) {
        guard isConnected else { return }
        
        webSocket?.send(.data(audioData)) { error in
            if let error = error {
                Logger.shared.log("Error sending audio: \(error)")
                print("Error sending audio: \(error)")
            }
        }
    }
    
    func clearTranscriptions() {
        transcriptionText = ""
        currentUtterance = ""
        interimText = ""
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                // Only log and update status if this wasn't an intentional disconnect
                if !self.isIntentionalDisconnect {
                    Logger.shared.log("WebSocket receive error: \(error)")
                    print("WebSocket receive error: \(error)")
                    self.connectionStatus = "Disconnected: \(error.localizedDescription)"
                }
                self.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            switch type {
            case "connection":
                self.connectionStatus = json["message"] as? String ?? "Connected"
                
            case "transcript":
                if let transcript = json["transcript"] as? String,
                   let isFinal = json["isFinal"] as? Bool {
                    // Check if delta is provided (new format) or use full transcript (old format)
                    let delta = json["delta"] as? String ?? transcript
                    
                    Logger.shared.log("Received transcript - Final: \(isFinal), Text: \(transcript)")
                    if isFinal {
                        // Final transcript - prepend to our text (newest first)
                        if !transcript.trimmingCharacters(in: .whitespaces).isEmpty {
                            self.transcriptionText = transcript + "\n" + self.transcriptionText
                            print("FINAL TRANSCRIPT: '\(transcript)'")
                            print("TOTAL TRANSCRIPTION SO FAR: '\(self.transcriptionText)'")
                        }
                        self.currentUtterance = ""
                        self.interimText = ""
                    } else {
                        // Interim transcript - show the full transcript
                        self.currentUtterance = transcript
                        self.interimText = delta
                        print("INTERIM TRANSCRIPT: '\(transcript)'")
                    }
                }
                
            case "error":
                if let error = json["error"] as? String {
                    self.connectionStatus = "Error: \(error)"
                }
                
            default:
                break
            }
        }
    }
}