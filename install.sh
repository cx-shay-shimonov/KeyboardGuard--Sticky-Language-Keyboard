#!/bin/bash
echo "🚀 KeyboardGuard Installation"
echo "=============================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This program only works on macOS"
    exit 1
fi

# Remove quarantine attribute and handle macOS security warnings
echo "🔓 Fixing macOS security attributes..."

# Remove quarantine attributes from all files
echo "   Removing quarantine from all files..."
xattr -cr . 2>/dev/null || true

# Make executable
chmod +x KeyboardGuard find_input_sources.swift

# Check for quarantine attributes
echo "   Checking for quarantine attributes..."
if xattr -l KeyboardGuard 2>/dev/null | grep -q quarantine; then
    echo "   ⚠️  Quarantine detected. Attempting to fix..."
    sudo xattr -cr . 2>/dev/null || true
    
    if xattr -l KeyboardGuard 2>/dev/null | grep -q quarantine; then
        echo "   ⚠️  Could not remove quarantine. Manual steps:"
        echo "      1. Right-click KeyboardGuard → Open (then click 'Open' in dialog)"
        echo "      2. Or temporarily disable Gatekeeper:"
        echo "         sudo spctl --master-disable"
        echo "         (Remember to re-enable later with: sudo spctl --master-enable)"
    else
        echo "   ✅ Quarantine removed successfully"
    fi
else
    echo "   ✅ No quarantine detected - binary should run without issues"
fi

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
