#!/bin/bash
echo "🚀 KeyboardGuard Installation"
echo "=============================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This program only works on macOS"
    exit 1
fi

# Remove quarantine attribute (fixes macOS "malware" warning)
echo "🔓 Removing quarantine attributes..."

echo "   Checking quarantine on KeyboardGuard:"
xattr -l KeyboardGuard

echo "   Attempting to remove quarantine from KeyboardGuard:"
if xattr -r -d com.apple.quarantine KeyboardGuard; then
    echo "   ✅ Successfully removed quarantine from KeyboardGuard"
else
    echo "   ❌ Failed to remove quarantine from KeyboardGuard (exit code: $?)"
fi

echo "   Attempting to remove quarantine from find_input_sources.swift:"
if xattr -r -d com.apple.quarantine find_input_sources.swift; then
    echo "   ✅ Successfully removed quarantine from find_input_sources.swift"
else
    echo "   ❌ Failed to remove quarantine from find_input_sources.swift (exit code: $?)"
fi

echo "   Attempting to remove quarantine from entire directory:"
if xattr -r -d com.apple.quarantine .; then
    echo "   ✅ Successfully removed quarantine from directory"
else
    echo "   ❌ Failed to remove quarantine from directory (exit code: $?)"
fi

echo "   Final check - quarantine on KeyboardGuard:"
xattr -l KeyboardGuard

# If quarantine is still present, try alternative methods
if xattr -l KeyboardGuard | grep -q quarantine; then
    echo "   ⚠️  Quarantine still present. Trying alternative methods..."
    
    echo "   Trying: sudo xattr -r -d com.apple.quarantine KeyboardGuard"
    if sudo xattr -r -d com.apple.quarantine KeyboardGuard; then
        echo "   ✅ Successfully removed with sudo"
    else
        echo "   ❌ Sudo method also failed"
    fi
    
    echo "   Trying: spctl --add --label 'KeyboardGuard' KeyboardGuard"
    if sudo spctl --add --label "KeyboardGuard" KeyboardGuard; then
        echo "   ✅ Added to Gatekeeper exceptions"
    else
        echo "   ❌ Gatekeeper exception failed"
    fi
fi

# Make executable
chmod +x KeyboardGuard find_input_sources.swift

echo ""
echo "🔍 Final verification:"
echo "   KeyboardGuard attributes:"
xattr -l KeyboardGuard
echo "   KeyboardGuard permissions:"
ls -la KeyboardGuard

echo "✅ KeyboardGuard is ready to use!"
echo ""
echo "📖 Quick Start:"
echo "  ./KeyboardGuard                    # Start with default settings"
echo "  ./KeyboardGuard -l portuguese      # Use Portuguese as default"
echo "  ./KeyboardGuard -t 30              # 30-second timeout"
echo "  ./KeyboardGuard --help             # Show all options"
echo ""
echo "🔧 To add custom languages:"
echo "  ./find_input_sources.swift         # Find input source IDs"
echo "  edit languages.json                # Add your language"
echo ""
echo "📚 See README.md for full documentation"
