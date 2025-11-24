#!/bin/bash

echo "🗑️  KeyboardGuard - Remove Program from Startup"
echo "=============================================="
echo ""

# Check if LaunchAgent exists
if [ ! -f ~/Library/LaunchAgents/com.user.keyboardguard.plist ]; then
    echo "ℹ️  KeyboardGuard is not set up for auto-start"
    echo "   No LaunchAgent found at ~/Library/LaunchAgents/com.user.keyboardguard.plist"
    exit 0
fi

echo "🔍 Found KeyboardGuard LaunchAgent"

# Check if it's currently loaded
if launchctl list | grep -q keyboardguard; then
    echo "🛑 Stopping KeyboardGuard service..."
    launchctl stop com.user.keyboardguard
    
    echo "📤 Unloading LaunchAgent..."
    launchctl unload ~/Library/LaunchAgents/com.user.keyboardguard.plist
    
    # Wait a moment
    sleep 1
fi

echo "🗂️  Removing LaunchAgent file..."
rm ~/Library/LaunchAgents/com.user.keyboardguard.plist

echo "✅ KeyboardGuard removed from startup"
echo ""

# Check if any processes are still running
PROCESSES=$(pgrep -f KeyboardGuard)
if [ ! -z "$PROCESSES" ]; then
    echo "⚠️  Warning: KeyboardGuard processes are still running:"
    ps aux | grep KeyboardGuard | grep -v grep
    echo ""
    echo "To stop them manually:"
    echo "   pkill KeyboardGuard"
else
    echo "✅ No KeyboardGuard processes running"
fi

echo ""
echo "🎉 Removal complete! KeyboardGuard will no longer start automatically."
echo ""
echo "To re-enable auto-start, run:"
echo "   ./add_program_to_startup.sh"
