#!/bin/bash

# Script to build and run ClaudeCodeVoiceControl on connected iPhone
# iPhone ID: 00008101-000359212650001E

echo "Building for iPhone..."

# Build the project
xcodebuild -project ClaudeCodeVoiceControl.xcodeproj \
  -scheme ClaudeCodeVoiceControl \
  -destination 'id=00008101-000359212650001E' \
  -configuration Debug \
  clean build

if [ $? -eq 0 ]; then
    echo "** BUILD SUCCEEDED **"
    echo "Installing and running on iPhone..."
    
    # Install the app on the device
    xcrun devicectl device install app \
      --device 00008101-000359212650001E \
      /Users/felixlunzenfichter/Library/Developer/Xcode/DerivedData/ClaudeCodeVoiceControl-*/Build/Products/Debug-iphoneos/ClaudeCodeVoiceControl.app
    
    if [ $? -eq 0 ]; then
        echo "App installed: iVoices.ch.ClaudeCodeVoiceControl"
        
        # Launch the app
        xcrun devicectl device process launch \
          --device 00008101-000359212650001E \
          iVoices.ch.ClaudeCodeVoiceControl
        
        if [ $? -eq 0 ]; then
            echo "Launched application successfully"
        else
            echo "Failed to launch application"
            exit 1
        fi
    else
        echo "Failed to install application"
        exit 1
    fi
else
    echo "** BUILD FAILED **"
    exit 1
fi