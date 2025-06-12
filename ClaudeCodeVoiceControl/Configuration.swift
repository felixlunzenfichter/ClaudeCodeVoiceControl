import Foundation

struct Configuration {
    // Update this URL after deploying your backend to Google Cloud Run
    // Format: wss://YOUR-SERVICE-NAME-XXXXX-uc.a.run.app
    static let backendURL = "wss://speech-transcription-1007452504573.us-central1.run.app"
    
    // For local testing, you can use:
    // static let backendURL = "ws://localhost:8080"
}