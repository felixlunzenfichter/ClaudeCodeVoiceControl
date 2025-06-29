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

// Track connected clients by type and name
const clients = {
  transcribers: new Set(),  // iOS devices sending audio
  receivers: new Map()      // Mac clients receiving transcriptions (name -> ws)
};

// Get current server statuses with active health check
async function getServerStatuses() {
  const statuses = {
    "Backend": true,  // Backend is always true if we're responding
    "Mac Receiver": false
  };
  
  // Check if Mac Receiver is actually responsive
  const macReceiver = clients.receivers.get("Mac Receiver");
  if (macReceiver && macReceiver.readyState === 1) { // 1 = OPEN
    try {
      // Send ping and wait for pong
      const pingId = Date.now().toString();
      const pongPromise = new Promise((resolve) => {
        const timeout = setTimeout(() => resolve(false), 1000); // 1 second timeout
        
        macReceiver.once('message', (data) => {
          try {
            const msg = JSON.parse(data.toString());
            if (msg.type === 'pong' && msg.pingId === pingId) {
              clearTimeout(timeout);
              resolve(true);
            }
          } catch (e) {}
        });
      });
      
      macReceiver.send(JSON.stringify({ type: 'ping', pingId }));
      statuses["Mac Receiver"] = await pongPromise;
    } catch (error) {
      console.log('Error pinging Mac Receiver:', error);
      statuses["Mac Receiver"] = false;
    }
  }
  
  return statuses;
}


// Handle WebSocket connections
wss.on('connection', (ws) => {
  console.log('Client connected');
  
  let clientType = 'transcriber'; // Default to transcriber for backward compatibility
  let recognizeStream = null;
  let previousTranscript = '';  // Track previous transcript for delta calculation
  
  // Send initial connection confirmation with server statuses
  getServerStatuses().then(statuses => {
    ws.send(JSON.stringify({ 
      type: 'connection', 
      status: 'connected',
      message: 'Ready to transcribe',
      serverStatuses: statuses
    }));
  });
  
  ws.on('message', async (data) => {
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
        
        if (message.type === 'identify') {
          // Client is identifying itself
          clientType = message.clientType || 'transcriber';
          const clientName = message.clientName || clientType;
          console.log(`Client identified as: ${clientType} (${clientName})`);
          
          // Add to appropriate client set
          if (clientType === 'receiver') {
            clients.receivers.set(clientName, ws);
            console.log(`Receiver '${clientName}' connected. Total receivers: ${clients.receivers.size}`);
          } else {
            clients.transcribers.add(ws);
            console.log(`Transcriber connected. Total transcribers: ${clients.transcribers.size}`);
          }
          
          // Confirm identification
          getServerStatuses().then(statuses => {
            ws.send(JSON.stringify({
              type: 'connection',
              status: 'identified',
              clientType: clientType,
              serverStatuses: statuses
            }));
          });
          
        } else if (message.type === 'start') {
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
                
                // Create transcript message
                const transcriptMessage = {
                  type: 'transcript',
                  transcript: transcript,      // Full transcript for reference
                  delta: delta,                // Only the new part
                  isFinal: isFinal,
                  timestamp: new Date().toISOString()
                };
                
                // Send to original transcriber
                ws.send(JSON.stringify(transcriptMessage));
                
                // Broadcast to all receivers
                const messageStr = JSON.stringify(transcriptMessage);
                for (const [name, receiver] of clients.receivers.entries()) {
                  if (receiver.readyState === receiver.OPEN) {
                    receiver.send(messageStr);
                  }
                }
                
                console.log(`${isFinal ? 'Final' : 'Interim'}: ${transcript} (delta: "${delta}")`);
                if (clients.receivers.size > 0) {
                  console.log(`Broadcast to ${clients.receivers.size} receiver(s)`);
                }
                
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
            
        } else if (message.type === 'requestStatus') {
          // Client is requesting current server statuses
          const statuses = await getServerStatuses();
          ws.send(JSON.stringify({
            type: 'serverStatusUpdate',
            serverStatuses: statuses
          }));
          
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
    console.log(`${clientType} disconnected`);
    
    // Remove from client sets
    let wasReceiver = false;
    
    // Check all receiver entries and remove matching websocket
    for (const [name, socket] of clients.receivers.entries()) {
      if (socket === ws) {
        clients.receivers.delete(name);
        wasReceiver = true;
        console.log(`Receiver '${name}' disconnected`);
        break;
      }
    }
    
    clients.transcribers.delete(ws);
    
    console.log(`Active clients - Transcribers: ${clients.transcribers.size}, Receivers: ${clients.receivers.size}`);
    
    
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