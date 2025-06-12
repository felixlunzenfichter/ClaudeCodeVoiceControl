//
//  ContentView.swift
//  ClaudeCodeVoiceControl
//
//  Created by Felix Lunzenfichter on 6/11/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var audioManager = AudioManager()
    @State private var pingProgress: CGFloat = 1.0
    @State private var animationTimer: Timer?
    
    func getConnectionColor() -> Color {
        if audioManager.transcriptionClient.connectionStatus.contains("Connecting") {
            return .purple
        } else if audioManager.isRecording && audioManager.transcriptionClient.isConnected {
            return .blue
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Audio level
            HStack {
                Text("Audio Level:")
                Text(String(format: "%.6f", audioManager.averageLevel))
                    .foregroundColor(audioManager.isRecording && audioManager.transcriptionClient.isConnected ? .blue : .red)
            }
            
            // Connection status
            HStack {
                Text("Connection:")
                Text(audioManager.transcriptionClient.connectionStatus)
                    .foregroundColor(getConnectionColor())
            }
            
            // Server statuses with animated dots
            HStack(spacing: 20) {
                // Transcription Backend
                HStack(spacing: 5) {
                    let backendConnected = audioManager.transcriptionClient.serverStatuses["Backend"] ?? false
                    Circle()
                        .fill(backendConnected ? Color.green : Color.red)
                        .frame(width: 10 * pingProgress, height: 10 * pingProgress)
                        .animation(.linear(duration: 0.1), value: pingProgress)
                    Text("Transcription Backend")
                        .font(.caption)
                }
                
                // Mac Receiver
                HStack(spacing: 5) {
                    let receiverConnected = audioManager.transcriptionClient.serverStatuses["Mac Receiver"] ?? false
                    Circle()
                        .fill(receiverConnected ? Color.green : Color.red)
                        .frame(width: 10 * pingProgress, height: 10 * pingProgress)
                        .animation(.linear(duration: 0.1), value: pingProgress)
                    Text("Mac Receiver")
                        .font(.caption)
                }
            }
            
            Divider()
            
            // Transcription section
            VStack(alignment: .leading, spacing: 5) {
                Text("Transcription:")
                    .font(.headline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        // Show current utterance being spoken (interim) at the TOP
                        if !audioManager.transcriptionClient.currentUtterance.isEmpty {
                            Text(audioManager.transcriptionClient.currentUtterance)
                                .foregroundColor(.blue)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Show final transcriptions below
                        if !audioManager.transcriptionClient.transcriptionText.isEmpty {
                            Text(audioManager.transcriptionClient.transcriptionText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Show waiting message if both are empty
                        if audioManager.transcriptionClient.transcriptionText.isEmpty && 
                           audioManager.transcriptionClient.currentUtterance.isEmpty {
                            Text("Waiting for speech...")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            }
            
            Spacer()
        }
        .padding()
        .task {
            audioManager.checkAndRequestPermission()
        }
        .onAppear {
            Logger.shared.log("ContentView onAppear called")
            
            // Only start timer if not already running
            if animationTimer == nil {
                Logger.shared.log("Starting animation timer")
                startAnimationTimer()
            }
            
            // Set up callback to reset animation on status update
            audioManager.transcriptionClient.onStatusUpdate = {
                // Reset to full size
                pingProgress = 1.0
                Logger.shared.log("Status update received, resetting animation to 1.0")
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
            Logger.shared.log("ContentView onDisappear - timer invalidated")
        }
    }
    
    func startAnimationTimer() {
        // Decrease progress gradually over 5 seconds
        // 0.05s interval * 100 updates = 5 seconds total
        // So decrease by 0.01 each update
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if pingProgress > 0 {
                withAnimation(.linear(duration: 0.05)) {
                    pingProgress = max(0, pingProgress - 0.01)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
