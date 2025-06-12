#!/bin/bash

# Start all servers for Claude Code Voice Control

echo "🚀 Starting Claude Code Voice Control System"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a process is running
check_process() {
    if pgrep -f "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Kill any existing servers
echo -e "${YELLOW}Stopping any existing servers...${NC}"
pkill -f "live-transcription-app/server.js" 2>/dev/null
pkill -f "mac-transcription-server/server.js" 2>/dev/null
sleep 2

# Start the Mac transcription server
echo -e "\n${GREEN}1. Starting Mac Transcription Server...${NC}"
cd /Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl/mac-transcription-server
node server.js &
MAC_PID=$!
echo "   Mac server PID: $MAC_PID"

# Wait longer for server to fully start
sleep 5

# Check if Mac server started successfully
if check_process "mac-transcription-server/server.js"; then
    echo -e "   ${GREEN}✓ Mac transcription server is running${NC}"
else
    echo -e "   ${RED}✗ Mac transcription server may still be starting...${NC}"
    # Don't exit, just warn
fi

echo -e "\n${GREEN}All servers started successfully!${NC}"
echo "============================================"
echo ""
echo "To stop all servers, press Ctrl+C or run:"
echo "pkill -f 'mac-transcription-server/server.js'"
echo ""
echo "Next steps:"
echo "1. Open the iOS app on your device"
echo "2. The app will auto-connect when you speak"
echo "3. Your voice will be transcribed in Claude Code"
echo ""
echo -e "${YELLOW}Note: The backend is already running on Google Cloud Run${NC}"
echo "Backend URL: https://speech-transcription-1007452504573.us-central1.run.app"

# Wait for interrupt
wait $MAC_PID