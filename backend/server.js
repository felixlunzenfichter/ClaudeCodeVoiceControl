const express = require('express');
const { WebSocketServer } = require('ws');
const speech = require('@google-cloud/speech');

const app = express();
const PORT = process.env.PORT || 8080;

// Basic health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'Speech Transcription Backend',
    timestamp: new Date().toISOString()
  });
});

// Start HTTP server
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Create WebSocket server
const wss = new WebSocketServer({ server });

// Google Speech client
const speechClient = new speech.SpeechClient();

// Handle WebSocket connections
wss.on('connection', (ws) => {
  console.log('Client connected');
  
  let recognizeStream = null;
  let previousTranscript = '';  // Track previous transcript for delta calculation
  
  // Send initial connection confirmation
  ws.send(JSON.stringify({ 
    type: 'connection', 
    status: 'connected',
    message: 'Ready to transcribe'
  }));
  
  ws.on('message', (data) => {
    try {
      // Check if it's a control message (JSON) or audio data (binary)
      if (Buffer.isBuffer(data) && data.length > 100) {
        // This is audio data - send directly without resampling
        console.log(`Received audio data: ${data.length} bytes`);
        if (recognizeStream && !recognizeStream.destroyed) {
          // Check if audio has actual content
          const samples = new Int16Array(data.buffer, data.byteOffset, data.length / 2);
          let maxAmplitude = 0;
          for (let i = 0; i < Math.min(100, samples.length); i++) {
            maxAmplitude = Math.max(maxAmplitude, Math.abs(samples[i]));
          }
          console.log(`Max amplitude in audio: ${maxAmplitude}`);
          
          recognizeStream.write(data);
        } else {
          console.log('No active recognition stream');
        }
      } else if (data.toString().startsWith('{')) {
        // This is a JSON control message
        const message = JSON.parse(data.toString());
        
        if (message.type === 'start') {
          // Start new recognition stream
          console.log('Starting recognition stream');
          
          const request = {
            config: {
              encoding: 'LINEAR16',
              sampleRateHertz: 44100,  // Accept 44.1kHz from iOS
              languageCode: message.languageCode || 'en-US',
              enableAutomaticPunctuation: true,
              model: 'latest_long',
            },
            interimResults: true,
          };
          
          recognizeStream = speechClient
            .streamingRecognize(request)
            .on('error', (error) => {
              console.error('Recognition error:', error);
              ws.send(JSON.stringify({ 
                type: 'error', 
                error: error.message 
              }));
              recognizeStream = null;
            })
            .on('data', (data) => {
              if (data.results[0] && data.results[0].alternatives[0]) {
                const transcript = data.results[0].alternatives[0].transcript;
                const isFinal = data.results[0].isFinal;
                
                // Calculate delta
                let delta = '';
                if (transcript.startsWith(previousTranscript)) {
                  // Extract only the new part
                  delta = transcript.substring(previousTranscript.length);
                } else {
                  // If it doesn't start with previous, send the whole thing
                  // This happens when Google revises the transcript
                  delta = transcript;
                }
                
                // Send delta transcript back to client
                ws.send(JSON.stringify({
                  type: 'transcript',
                  transcript: transcript,      // Full transcript for reference
                  delta: delta,                // Only the new part
                  isFinal: isFinal,
                  timestamp: new Date().toISOString()
                }));
                
                console.log(`${isFinal ? 'Final' : 'Interim'}: ${transcript} (delta: "${delta}")`);
                
                // Update previous transcript
                if (isFinal) {
                  // Reset for next utterance
                  previousTranscript = '';
                } else {
                  // Keep track for next interim
                  previousTranscript = transcript;
                }
              }
            });
            
        } else if (message.type === 'stop') {
          // Stop recognition
          if (recognizeStream) {
            recognizeStream.end();
            recognizeStream = null;
            console.log('Stopped recognition stream');
          }
        }
      }
    } catch (error) {
      console.error('Error processing message:', error);
      ws.send(JSON.stringify({ 
        type: 'error', 
        error: error.message 
      }));
    }
  });
  
  ws.on('close', () => {
    console.log('Client disconnected');
    if (recognizeStream) {
      recognizeStream.end();
    }
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
  });
});