# Backend Deployment Documentation

This documents how Claude Code successfully deployed the speech transcription backend to Google Cloud Run.

## How I Deploy the Backend

When deploying the backend, I follow these exact steps that have been proven to work:

### 1. Set the correct Google Cloud project
```bash
gcloud config set project gen-lang-client-0047710702
```

This is the project (Gemini API) that has the necessary APIs enabled and permissions configured.

### 2. Deploy directly from the backend directory
```bash
cd /Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl/backend
gcloud run deploy speech-transcription --source . --region us-central1 --allow-unauthenticated
```

### 3. What happens during deployment
- Cloud Build automatically detects the Dockerfile
- It builds the container image
- Uploads it to Google Container Registry
- Deploys to Cloud Run with WebSocket support enabled
- Returns the service URL: `https://speech-transcription-1007452504573.us-central1.run.app`

## Key Configuration Details

### Backend server.js requirements:
- Accepts WebSocket connections on the PORT environment variable
- Handles 44.1kHz audio directly (no resampling needed)
- Sends delta transcriptions for live feedback
- Uses Google Speech-to-Text streaming API

### iOS app configuration:
- Update `Configuration.swift` with the Cloud Run URL
- Ensure network entitlements are enabled
- Record at 44.1kHz and send LINEAR16 format

## Authentication
The deployed service runs with Cloud Run's default service account which has access to:
- Google Speech-to-Text API
- Cloud Logging
- Container Registry

No manual credential setup is needed - Cloud Run handles this automatically.

## Monitoring Deployment
To check deployment status:
```bash
gcloud run services describe speech-transcription --region us-central1
```

To view logs:
```bash
gcloud run services logs read speech-transcription --region us-central1 --limit 50
```

## Important Notes
- The backend accepts 44.1kHz audio directly from iOS
- No audio resampling is performed (it corrupts the audio)
- WebSocket support is automatically enabled by Cloud Run
- The service scales to zero when not in use (cost-effective)