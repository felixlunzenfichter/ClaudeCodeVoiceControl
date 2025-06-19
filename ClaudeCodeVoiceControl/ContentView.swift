import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    
    var body: some View {
        VStack {
            Text("Real-Time Transcription")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                viewModel.toggleRecording()
            }) {
                Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                    .font(.title2)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(viewModel.transcriptions.enumerated()), id: \.offset) { index, transcription in
                        HStack {
                            Text(transcription)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}
