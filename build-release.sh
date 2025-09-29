#!/bin/bash
set -e

VERSION=${1:-"dev"}
RELEASE_DIR="KeyboardGuard-${VERSION}"

echo "🔨 Building KeyboardGuard release ${VERSION}..."

# Clean previous builds
rm -rf "${RELEASE_DIR}" "${RELEASE_DIR}.tar.gz" KeyboardGuard 2>/dev/null || true

# Build optimized binary
echo "📦 Compiling optimized binary..."
swiftc KeyboardGuard.swift -o KeyboardGuard \
  -framework Foundation \
  -framework Carbon \
  -framework AppKit \
  -framework IOKit \
  -O \
  -whole-module-optimization

# Sign the binary with ad-hoc signature to prevent Gatekeeper issues
echo "🔏 Signing binary with ad-hoc signature..."
if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - KeyboardGuard
    echo "✅ Binary signed successfully"
else
    echo "⚠️  codesign not available, skipping signing"
fi

# Create release package
echo "📋 Creating release package..."
mkdir -p "${RELEASE_DIR}"

# Copy essential files
cp KeyboardGuard "${RELEASE_DIR}/"
cp languages.json "${RELEASE_DIR}/"
cp find_input_sources.swift "${RELEASE_DIR}/"
cp README.md "${RELEASE_DIR}/"
cp LICENSE "${RELEASE_DIR}/"

# Make scripts executable
chmod +x "${RELEASE_DIR}/KeyboardGuard"
chmod +x "${RELEASE_DIR}/find_input_sources.swift"

# Copy the installation script (which handles code signing issues)
echo "📄 Copying installation script..."
cp install.sh "${RELEASE_DIR}/"

chmod +x "${RELEASE_DIR}/install.sh"

# Create tarball
echo "📦 Creating archive..."
tar -czf "${RELEASE_DIR}.tar.gz" "${RELEASE_DIR}/"

# Show results
echo ""
echo "✅ Release build complete!"
echo "📦 Archive: ${RELEASE_DIR}.tar.gz"
echo "📁 Directory: ${RELEASE_DIR}/"
echo "📊 Size: $(du -h "${RELEASE_DIR}.tar.gz" | cut -f1)"
echo ""
echo "🚀 Ready for GitHub Release!"

# Test the binary
echo "🧪 Testing binary..."
if ./"${RELEASE_DIR}"/KeyboardGuard --help > /dev/null 2>&1; then
    echo "✅ Binary test passed"
else
    echo "❌ Binary test failed"
    exit 1
fi
