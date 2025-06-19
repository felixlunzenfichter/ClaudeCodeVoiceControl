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
    
    # Find the most recent build
    APP_PATH=$(find /Users/felixlunzenfichter/Library/Developer/Xcode/DerivedData -name "ClaudeCodeVoiceControl.app" -path "*/Build/Products/Debug-iphoneos/*" | head -n 1)
    
    if [ -z "$APP_PATH" ]; then
        echo "Could not find built app"
        exit 1
    fi
    
    echo "Installing app from: $APP_PATH"
    
    # Install the app on the device
    xcrun devicectl device install app \
      --device 00008101-000359212650001E \
      "$APP_PATH"
    
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