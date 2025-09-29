#!/bin/bash

echo "=== KeyboardGuard Status Check ==="
echo ""

echo "1. Checking for running processes..."
PROCESSES=$(pgrep -f KeyboardGuard)
if [ -z "$PROCESSES" ]; then
    echo "   ✅ No KeyboardGuard processes found"
else
    echo "   ⚠️  Found running processes:"
    ps aux | grep KeyboardGuard | grep -v grep
fi

echo ""
echo "2. Checking LaunchAgent status..."
LAUNCHAGENT=$(launchctl list | grep keyboardguard)
if [ -z "$LAUNCHAGENT" ]; then
    echo "   ✅ No KeyboardGuard LaunchAgent loaded"
else
    echo "   ⚠️  LaunchAgent is loaded:"
    echo "   $LAUNCHAGENT"
fi

echo ""
echo "3. Checking for log files..."
if ls *.log 1> /dev/null 2>&1; then
    echo "   📋 Found log files:"
    ls -la *.log
else
    echo "   ✅ No log files found"
fi

echo ""
echo "4. Checking LaunchAgent file..."
if [ -f "$HOME/Library/LaunchAgents/com.user.keyboardguard.plist" ]; then
    echo "   📄 LaunchAgent file exists: $HOME/Library/LaunchAgents/com.user.keyboardguard.plist"
else
    echo "   ✅ No LaunchAgent file found"
fi

echo ""
echo "=== Status Check Complete ==="
