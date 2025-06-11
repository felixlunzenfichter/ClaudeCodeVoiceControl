//
//  ContentView.swift
//  ClaudeCodeVoiceControl
//
//  Created by Felix Lunzenfichter on 6/11/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var permissionStatus = "Checking..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Microphone Permission")
                .font(.title)
            
            Text("Status: \(permissionStatus)")
                .font(.headline)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 200)
        .onAppear {
            checkAndRequestPermission()
        }
    }
    
    func checkAndRequestPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            permissionStatus = "Already Granted ✅"
        case .denied:
            permissionStatus = "Denied ❌"
        case .restricted:
            permissionStatus = "Restricted ⚠️"
        case .notDetermined:
            permissionStatus = "Requesting..."
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    permissionStatus = granted ? "Granted ✅" : "Denied ❌"
                }
            }
        @unknown default:
            permissionStatus = "Unknown"
        }
    }
}

#Preview {
    ContentView()
}
