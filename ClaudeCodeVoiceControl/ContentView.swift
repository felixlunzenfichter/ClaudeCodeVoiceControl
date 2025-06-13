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
    @State private var transcriptHistory: [String] = []
    
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
        VStack(spacing: 0) {
            // Main area - transcript history (terminal view)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(transcriptHistory.enumerated()), id: \.offset) { index, transcript in
                            HStack(alignment: .top, spacing: 8) {
                                Text(">")
                                    .foregroundColor(.green)
                                    .font(.system(.body, design: .monospaced))
                                Text(transcript)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .id(index)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: transcriptHistory.count) { _ in
                    // Auto-scroll to bottom when new transcript is added
                    withAnimation {
                        proxy.scrollTo(transcriptHistory.count - 1, anchor: .bottom)
                    }
                }
            }
            .background(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom bar with all controls
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .top, spacing: 12) {
                    // Live transcription - Takes all available space
                    VStack(alignment: .leading, spacing: 4) {
                        if !audioManager.transcriptionClient.currentUtterance.isEmpty {
                            // Show current utterance being spoken
                            Text(audioManager.transcriptionClient.currentUtterance)
                                .foregroundColor(.blue)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if !audioManager.transcriptionClient.latestFinalTranscript.isEmpty {
                            // Show the latest final transcript
                            Text(audioManager.transcriptionClient.latestFinalTranscript)
                                .foregroundColor(.primary)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Waiting for speech...")
                                .foregroundColor(.gray)
                                .italic()
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Status box - Bottom right
                    VStack(alignment: .leading, spacing: 4) {
                        // Box 1: Google Transcription and Mac Server
                        VStack(alignment: .leading, spacing: 4) {
                            // Backend status with animation
                            HStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(audioManager.transcriptionClient.serverStatuses["Backend"] ?? false ? Color.green : Color.red)
                                        .frame(width: 6 * pingProgress, height: 6 * pingProgress)
                                        .animation(.linear(duration: 0.1), value: pingProgress)
                                }
                                Text("Google Transcription")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Mac server status with animation
                            HStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(audioManager.transcriptionClient.serverStatuses["Mac Receiver"] ?? false ? Color.green : Color.red)
                                        .frame(width: 6 * pingProgress, height: 6 * pingProgress)
                                        .animation(.linear(duration: 0.1), value: pingProgress)
                                }
                                Text("Mac Server")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        
                        // Box 2: Audio Level and Transcribing status - Clickable
                        Button(action: {
                            audioManager.autoTranscribeEnabled.toggle()
                            if !audioManager.autoTranscribeEnabled && audioManager.transcriptionClient.isRecognizing {
                                audioManager.transcriptionClient.stopRecognition()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                // Audio Level
                                HStack(spacing: 2) {
                                    Text("Audio:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.6f", audioManager.averageLevel))
                                        .font(.caption2)
                                        .foregroundColor(audioManager.transcriptionClient.isRecognizing ? .blue : .red)
                                        .monospaced()
                                }
                                
                                // Transcribing status
                                HStack(spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(audioManager.transcriptionClient.isRecognizing ? .blue : .red)
                                    Text(audioManager.transcriptionClient.isRecognizing ? "Transcribing" : "Not transcribing")
                                        .font(.caption2)
                                        .foregroundColor(audioManager.transcriptionClient.isRecognizing ? .blue : .red)
                                }
                            }
                            .padding(6)
                            .background(audioManager.autoTranscribeEnabled ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                            .cornerRadius(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!audioManager.transcriptionClient.isConnected)
                        .opacity(audioManager.transcriptionClient.isConnected ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.05))
            }
        }
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
            
            // Set up callback for when transcription is complete
            audioManager.transcriptionClient.onTranscriptionComplete = { transcript in
                // Add to terminal history
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.transcriptHistory.append(transcript)
                }
                
                // Clear the latest transcript after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.audioManager.transcriptionClient.latestFinalTranscript = ""
                }
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
            Logger.shared.log("ContentView onDisappear - timer invalidated")
        }
    }
    
    func startAnimationTimer() {
        // Decrease progress gradually over 3 seconds
        // 0.03s interval * 100 updates = 3 seconds total
        // So decrease by 0.01 each update
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            if pingProgress > 0 {
                withAnimation(.linear(duration: 0.03)) {
                    pingProgress = max(0, pingProgress - 0.01)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
