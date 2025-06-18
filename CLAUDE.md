# ClaudeCodeVoiceControl - Stable Version

## Current Version
**Branch**: `development`  
**Commit**: `babf1e3 Redesign UI with clean minimal layout and improved transcription flow`

This is the **STABLE** version used for daily voice control accessibility. Do not modify this version - it provides reliable voice access during development.

## How to Run

### 1. Install Dependencies
```bash
cd mac-transcription-server
npm install
```

### 2. Start Voice Control System
```bash
cd mac-transcription-server
node server.js
```

This will:
- Connect to Google Cloud transcription backend
- Start Mac transcription server
- Enable voice-to-text input for Claude Code
- Provide full accessibility through voice commands

### 3. iOS App
The iOS app should already be installed on iPhone (ID: 00008101-000359212650001E)
- Unlock iPhone to launch app
- App connects automatically to Mac server
- Provides voice transcription interface

## System Requirements
- Terminal accessibility permissions granted
- iPhone connected and trusted
- Google Cloud backend running
- Voice transcription permissions enabled

## Purpose
This stable version ensures continuous accessibility while experimental TDD development happens in the separate ClaudeCodeVoiceControl-TDD repository.