#!/bin/bash
# Web Bridge for Android Emulator Control
# Provides browser-based access to VaultNote APK

PORT=${1:-8080}
ADB_PORT=5554

echo "=== VaultNote Emulator Web Bridge ==="
echo "Starting on port $PORT..."

# Start ADB server
/home/blue/sdk/android/platform-tools/adb kill-server 2>/dev/null
/home/blue/sdk/android/platform-tools/adb start-server

# Wait for emulator
echo "Waiting for emulator..."
timeout 60 /home/blue/sdk/android/platform-tools/adb wait-for-device

if [ $? -eq 0 ]; then
    echo "Emulator connected!"
    
    # Install APK
    APK_PATH="/home/blue/projects/vaultnote/flutter/build/app/outputs/apk/release/app-universal-release.apk"
    if [ -f "$APK_PATH" ]; then
        echo "Installing APK..."
        /home/blue/sdk/android/platform-tools/adb install -r "$APK_PATH"
    fi
    
    # Launch app
    echo "Launching VaultNote..."
    /home/blue/sdk/android/platform-tools/adb shell am start -n com.vaultnote.vaultnote/.MainActivity
    
    echo "=== Access Instructions ==="
    echo "1. Emulator is running on port $ADB_PORT"
    echo "2. Use scrcpy to view: scrcpy -s emulator-$ADB_PORT"
    echo "3. Or use Android Studio to connect"
else
    echo "Emulator not detected. Please start emulator manually."
fi