#!/bin/bash

echo "🚀 KeyboardGuard - Add Program to Startup"
echo "================================="
echo ""

# Get the current directory (where KeyboardGuard is located)
KEYBOARDGUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYBOARDGUARD_PATH="$KEYBOARDGUARD_DIR/KeyboardGuard"

# Check if KeyboardGuard exists
if [ ! -f "$KEYBOARDGUARD_PATH" ]; then
    echo "❌ Error: KeyboardGuard binary not found at $KEYBOARDGUARD_PATH"
    echo "   Please run this script from the KeyboardGuard directory."
    exit 1
fi

echo "📍 KeyboardGuard found at: $KEYBOARDGUARD_PATH"
echo ""

# Create LaunchAgent directory
mkdir -p ~/Library/LaunchAgents
mkdir -p ~/Library/Logs

# Create the plist file with the correct path
cat > ~/Library/LaunchAgents/com.user.keyboardguard.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.keyboardguard</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$KEYBOARDGUARD_PATH</string>
        <string>-t</string>
        <string>10</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/keyboardguard.log</string>
    
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/keyboardguard.error.log</string>
    
    <key>WorkingDirectory</key>
    <string>$KEYBOARDGUARD_DIR</string>
    
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

echo "✅ LaunchAgent plist created"

# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.keyboardguard.plist

echo "✅ LaunchAgent loaded and started"
echo ""

# Wait a moment for it to start
sleep 2

# Check if it's running
if launchctl list | grep -q keyboardguard; then
    echo "🎉 SUCCESS! KeyboardGuard is now running and will auto-start on login"
    echo ""
    echo "📊 Status:"
    launchctl list | grep keyboardguard
    echo ""
    echo "📝 Logs will be written to:"
    echo "   Output: ~/Library/Logs/keyboardguard.log"
    echo "   Errors: ~/Library/Logs/keyboardguard.error.log"
    echo ""
    echo "🔧 Management commands:"
    echo "   Stop:    launchctl stop com.user.keyboardguard"
    echo "   Start:   launchctl start com.user.keyboardguard"
    echo "   Disable: launchctl unload ~/Library/LaunchAgents/com.user.keyboardguard.plist"
    echo "   Status:  ./check_status.sh"
else
    echo "❌ Failed to start KeyboardGuard"
    echo "   Check the error log: ~/Library/Logs/keyboardguard.error.log"
fi
