#!/bin/bash

# Script to open Xcode, run the app, and return to terminal
# Uses AppleScript to automate Xcode

echo "Opening Xcode and running the app..."

# Open the Xcode project
open /Users/felixlunzenfichter/Documents/ClaudeCodeVoiceControl/ClaudeCodeVoiceControl.xcodeproj

# Wait for Xcode to fully load
sleep 5

# Use AppleScript to press the Run button
osascript <<EOF
tell application "Xcode"
    activate
    tell application "System Events"
        tell process "Xcode"
            -- Press Cmd+R to run
            keystroke "r" using command down
        end tell
    end tell
end tell
EOF

# Wait a moment for the build to start
sleep 2

# Return focus to Terminal
osascript <<EOF
tell application "Terminal"
    activate
end tell
EOF

echo "App is building and running in Xcode. Terminal is now active."