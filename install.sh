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

# Check if KeyboardGuard can be executed
echo "   Testing binary execution..."
if ./KeyboardGuard --version >/dev/null 2>&1; then
    echo "   ✅ Binary executes without warnings"
elif xattr -l KeyboardGuard 2>/dev/null | grep -q quarantine; then
    echo "   ⚠️  Quarantine detected. Attempting to fix..."
    
    # Try to remove quarantine with more forceful methods
    sudo xattr -cr . 2>/dev/null || true
    
    # If still problematic, inform user of manual solution
    if ! ./KeyboardGuard --version >/dev/null 2>&1; then
        echo "   ⚠️  Manual intervention required:"
        echo "      Run: sudo spctl --master-disable"
        echo "      Then: System Preferences > Security & Privacy > Allow apps from anywhere"
        echo "      After running KeyboardGuard once, you can re-enable Gatekeeper"
    fi
else
    echo "   ⚠️  Unknown execution issue. You may need to:"
    echo "      1. Right-click KeyboardGuard → Open"
    echo "      2. Or run: sudo spctl --master-disable (temporarily)"
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
