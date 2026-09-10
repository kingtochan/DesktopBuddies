#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="DesktopBuddies"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_CONFIG="release"

echo "=========================================="
echo " Building ${APP_NAME} for macOS (ARM64) "
echo " (No Apple Developer License Required)   "
echo "=========================================="

# 1. Compile Swift package in release mode
echo "==> Compiling Swift package..."
swift build -c ${BUILD_CONFIG}

# 2. Prepare App Bundle directory structure
echo "==> Assembling ${BUNDLE_NAME}..."
rm -rf "${BUNDLE_NAME}"
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# 3. Copy binary
cp ".build/${BUILD_CONFIG}/${APP_NAME}" "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"
chmod +x "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"

# 4. Copy App Icon if present
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${BUNDLE_NAME}/Contents/Resources/AppIcon.icns"
fi

# 5. Generate Info.plist
cat << 'EOF' > "${BUNDLE_NAME}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DesktopBuddies</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.DesktopBuddies</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Desktop Buddies</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 6. Ad-hoc sign the bundle for local ARM64 execution (NO developer account needed)
echo "==> Ad-hoc signing app bundle..."
codesign --force --deep -s - "${BUNDLE_NAME}"

# 7. Verification
echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${BUNDLE_NAME}"

echo ""
echo "=========================================================="
echo " BUILD SUCCESSFUL! "
echo " App Bundle created: ${SCRIPT_DIR}/${BUNDLE_NAME}"
echo "=========================================================="
echo ""
echo "To run now, run:"
echo "    open ${BUNDLE_NAME}"
echo ""
echo "To install to /Applications, run:"
echo "    cp -R ${BUNDLE_NAME} /Applications/"
echo ""

if [ "$1" == "--run" ]; then
    echo "Launching ${BUNDLE_NAME}..."
    open "${BUNDLE_NAME}"
fi
