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
    }
}

#Preview {
    ContentView()
}
