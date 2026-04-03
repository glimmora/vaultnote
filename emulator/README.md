# VaultNote Emulator Access Guide

## 🚀 Quick Start

### 1. Emulator Status
- **Emulator**: Running on port 5554
- **Web Server**: Running on port 8090
- **Status Page**: `http://localhost:8090/status.html`

### 2. Access Methods

#### Method 1: scrcpy (Recommended)
```bash
# Install scrcpy if not already installed
# Then run:
scrcpy -s emulator-5554
```

This will open a window showing the emulator screen where you can interact with it directly.

#### Method 2: Web Control Panel
Open in browser: `http://localhost:8090/`

Features:
- Start/Stop emulator
- Install APK
- Launch VaultNote app
- Send key events (Back, Home, etc.)
- Real-time status monitoring

#### Method 3: Status Page
Open in browser: `http://localhost:8090/status.html`

Shows:
- System status
- Emulator information
- APK details
- Troubleshooting guide

### 3. Manual Commands

#### Check Emulator Status
```bash
adb devices -l
adb shell getprop sys.boot_completed
```

#### Install APK
```bash
adb install -r /home/blue/projects/vaultnote/flutter/build/app/outputs/apk/release/app-universal-release.apk
```

#### Launch VaultNote
```bash
adb shell am start -n com.vaultnote.vaultnote/.MainActivity
```

#### Send Key Events
```bash
adb shell input keyevent KEYCODE_BACK      # Back button
adb shell input keyevent KEYCODE_HOME      # Home button
adb shell input keyevent KEYCODE_ENTER     # Enter/OK
```

### 4. Troubleshooting

#### Emulator Not Responding
```bash
# Kill and restart emulator
adb emu kill
nohup /home/blue/sdk/android/emulator/emulator -avd vaultnote_default -no-audio -no-window -no-accel -gpu swiftshader_indirect -port 5554 &
```

#### APK Installation Failed
```bash
# Try manual push and install
adb push /home/blue/projects/vaultnote/flutter/build/app/outputs/apk/release/app-universal-release.apk /data/local/tmp/vaultnote.apk
adb shell pm install /data/local/tmp/vaultnote.apk
```

#### Check Logs
```bash
tail -f /home/blue/projects/vaultnote/emulator/emulator_final.log
```

### 5. Files Location

```
vaultnote/emulator/
├── README.md                    # This file
├── status.html                  # Status page
├── server.js                    # Web server
├── web-bridge.sh               # Web bridge script
├── emulator_final.log          # Emulator log
└── vaultnote_default.avd/      # AVD files
```

### 6. APK Files

Location: `/home/blue/projects/vaultnote/flutter/build/app/outputs/apk/release/`

- `app-universal-release.apk` (51 MB) - Universal APK
- `app-arm64-v8a-release.apk` (19 MB) - ARM64
- `app-armeabi-v7a-release.apk` (17 MB) - ARM
- `app-x86_64-release.apk` (20 MB) - x86_64

### 7. Notes

- Emulator runs in **software rendering mode** (no hardware acceleration)
- Cold boot takes 2-3 minutes on first run
- Package manager may take time to initialize
- Use `scrcpy` for best visual access
- Web control panel provides remote control capabilities

## 🔗 Links

- **Web Control Panel**: http://localhost:8090/
- **Status Page**: http://localhost:8090/status.html
- **VaultNote Repository**: /home/blue/projects/vaultnote

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review emulator logs: `tail -f /home/blue/projects/vaultnote/emulator/emulator_final.log`
3. Restart emulator if needed