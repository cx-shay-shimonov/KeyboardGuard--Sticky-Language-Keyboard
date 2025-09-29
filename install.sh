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
if xattr -r -d com.apple.quarantine KeyboardGuard 2>/dev/null; then
    echo "   ✅ Removed quarantine from KeyboardGuard"
else
    echo "   ℹ️  No quarantine found on KeyboardGuard (or already removed)"
fi

if xattr -r -d com.apple.quarantine find_input_sources.swift 2>/dev/null; then
    echo "   ✅ Removed quarantine from find_input_sources.swift"
else
    echo "   ℹ️  No quarantine found on find_input_sources.swift (or already removed)"
fi

# Also remove quarantine from the entire directory and all files
xattr -r -d com.apple.quarantine . 2>/dev/null || true

# Make executable
chmod +x KeyboardGuard find_input_sources.swift

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
