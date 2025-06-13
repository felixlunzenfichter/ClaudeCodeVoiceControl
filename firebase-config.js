// Firebase configuration for Claude Code Voice Control
// This configuration will be used by both the Mac server and iOS app

const firebaseConfig = {
  // These values need to be filled in after creating the Firebase project
  // through the Firebase Console at https://console.firebase.google.com
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Firestore collections structure
const collections = {
  terminals: 'terminals',        // Terminal sessions
  messages: 'messages'          // Terminal messages within each session
};

// Message structure for Firestore
const messageSchema = {
  sessionId: '',      // Terminal session ID
  timestamp: null,    // Firestore server timestamp
  type: '',          // 'input' | 'output' | 'error' | 'system'
  content: '',       // The actual message content
  source: '',        // 'user' | 'claude' | 'system'
  metadata: {}       // Additional metadata (optional)
};

module.exports = {
  firebaseConfig,
  collections,
  messageSchema
};