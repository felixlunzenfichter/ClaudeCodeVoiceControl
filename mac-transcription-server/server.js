const WebSocket = require('ws');
const { exec, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Configuration
const BACKEND_URL = process.env.BACKEND_URL || 'wss://speech-transcription-1007452504573.us-central1.run.app';
const RECONNECT_DELAY = 5000; // 5 seconds

class TranscriptionReceiver {
  constructor() {
    this.ws = null;
    this.isConnected = false;
    this.reconnectTimer = null;
    this.claudeProcess = null;
    this.claudeOutput = '';
    this.firestore = null; // Will be initialized when Firebase is configured
  }

  connect() {
    console.log(`Connecting to backend: ${BACKEND_URL}`);
    
    this.ws = new WebSocket(BACKEND_URL);

    this.ws.on('open', () => {
      console.log('Connected to transcription backend');
      this.isConnected = true;
      
      // Send identification as receiver
      this.ws.send(JSON.stringify({
        type: 'identify',
        clientType: 'receiver',
        clientName: 'Mac Receiver',
        platform: 'mac'
      }));
    });

    this.ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        this.handleMessage(message);
      } catch (error) {
        console.error('Error parsing message:', error);
      }
    });

    this.ws.on('close', () => {
      console.log('Disconnected from backend');
      this.isConnected = false;
      this.scheduleReconnect();
    });

    this.ws.on('error', (error) => {
      console.error('WebSocket error:', error.message);
    });
  }

  handleMessage(message) {
    switch (message.type) {
      case 'connection':
        console.log('Backend says:', message.message);
        break;
        
      case 'transcript':
        if (message.isFinal) {
          console.log(`Final transcript: "${message.transcript}"`);
          this.typeTranscription(message.transcript);
        } else {
          console.log(`Interim: "${message.transcript}"`);
        }
        break;
        
      case 'error':
        console.error('Backend error:', message.error);
        break;
        
      case 'ping':
        // Respond to health check
        this.ws.send(JSON.stringify({
          type: 'pong',
          pingId: message.pingId
        }));
        break;
        
      default:
        console.log('Unknown message type:', message.type);
    }
  }

  startClaudeCode() {
    console.log('Starting Claude Code...');
    
    // Start Claude Code with dangerous skip permissions for accessibility
    this.claudeProcess = spawn('claude', ['--dangerously-skip-permissions'], {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, TERM: 'xterm-256color' }
    });
    
    // Handle Claude Code output
    this.claudeProcess.stdout.on('data', (data) => {
      const output = data.toString();
      console.log('Claude:', output);
      this.claudeOutput += output;
      
      // Send to backend/Firestore when configured
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({
          type: 'claude_output',
          content: output,
          timestamp: new Date().toISOString()
        }));
      }
    });
    
    this.claudeProcess.stderr.on('data', (data) => {
      console.error('Claude Error:', data.toString());
    });
    
    this.claudeProcess.on('exit', (code) => {
      console.log(`Claude Code exited with code ${code}`);
      this.claudeProcess = null;
      
      // Restart Claude Code after a delay
      setTimeout(() => this.startClaudeCode(), 5000);
    });
  }
  
  typeTranscription(text) {
    if (!text || text.trim() === '') return;
    
    // If Claude Code is running, send the text to it
    if (this.claudeProcess && !this.claudeProcess.killed) {
      console.log(`Sending to Claude: "${text}"`);
      this.claudeProcess.stdin.write(text + '\n');
      
      // Also send input to backend/Firestore when configured
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({
          type: 'claude_input',
          content: text,
          timestamp: new Date().toISOString()
        }));
      }
    } else {
      console.log('Claude Code not running, starting it...');
      this.startClaudeCode();
      // Queue the text to be sent after Claude starts
      setTimeout(() => {
        if (this.claudeProcess) {
          this.claudeProcess.stdin.write(text + '\n');
        }
      }, 2000);
    }
  }

  scheduleReconnect() {
    if (this.reconnectTimer) return;
    
    console.log(`Reconnecting in ${RECONNECT_DELAY / 1000} seconds...`);
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, RECONNECT_DELAY);
  }

  stop() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    
    if (this.claudeProcess) {
      console.log('Stopping Claude Code...');
      this.claudeProcess.kill();
      this.claudeProcess = null;
    }
  }
}

// Start the receiver
const receiver = new TranscriptionReceiver();
receiver.connect();

// Start Claude Code after a short delay
setTimeout(() => {
  receiver.startClaudeCode();
}, 2000);

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down...');
  receiver.stop();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\nShutting down...');
  receiver.stop();
  process.exit(0);
});

console.log('Mac Transcription Server with Claude Code Integration');
console.log('=======================================================');
console.log('Voice transcriptions will be sent to Claude Code');
console.log('Claude Code output will be synced to all devices (once Firebase is configured)');
console.log('');
console.log('Press Ctrl+C to stop');
console.log('');
console.log('Requirements:');
console.log('1. Claude Code CLI must be installed');
console.log('2. Terminal must have accessibility permissions');
console.log('3. Firebase must be configured (see FIREBASE_SETUP.md)');