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
    
    var body: some View {
        VStack(spacing: 20) {
            if audioManager.permissionStatus != "Granted ✅" {
                Text("Status: \(audioManager.permissionStatus)")
                    .font(.headline)
            }
            
            if audioManager.isRecording {
                Text(String(format: "%.6f", audioManager.averageLevel))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(audioManager.averageLevel == 0 ? .red : .green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            audioManager.checkAndRequestPermission()
        }
    }
}

#Preview {
    ContentView()
}
