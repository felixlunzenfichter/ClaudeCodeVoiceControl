# Firebase Setup Instructions

Since Firebase CLI requires interactive authentication, you'll need to complete these steps manually:

## 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Create a project"
3. Enter project name: `claude-code-voice-control`
4. Disable Google Analytics (not needed)
5. Click "Create Project"

## 2. Enable Firestore

1. In the Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in production mode"
4. Select your preferred region (us-central1 recommended)
5. Click "Enable"

## 3. Get Configuration

1. In Project Settings (gear icon)
2. Scroll to "Your apps" section
3. Click "</>" (Web app) icon
4. Register app with name: "Claude Code Voice Control"
5. Copy the configuration values
6. Update `firebase-config.js` with your values

## 4. Set Security Rules

After setup, go to Firestore Rules and add:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all terminals and messages
    match /terminals/{terminal} {
      allow read, write: if true;
      
      match /messages/{message} {
        allow read, write: if true;
      }
    }
  }
}
```

## 5. Install Firebase SDK

The necessary dependencies are already in package.json.
Run `npm install` in the mac-transcription-server directory.

## What Gets Synced

- All Claude Code input/output
- Terminal session history
- Real-time updates across all devices
- Session metadata and timestamps