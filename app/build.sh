#!/bin/bash
# Build MacPlay.app: compile the SwiftUI executable, bundle it with the
# Python engine + games DB in Resources/engine, ad-hoc sign.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

# The Release workflow passes the version it computed; local builds use the last release tag.
VERSION="${MACPLAY_VERSION:-$( (git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true) | sed -E 's/^v//; s/-.*//')}"
VERSION="${VERSION:-0.0.0}"
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"

APP="dist/MacPlay.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/engine/data"

cp .build/release/MacPlay "$APP/Contents/MacOS/MacPlay"
# engine is fully native Swift now; only the games DB ships as a resource
cp ../data/games.json ../data/compatibility.json "$APP/Contents/Resources/engine/data/"
cp icon/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>MacPlay</string>
  <key>CFBundleIdentifier</key><string>com.macplay.app</string>
  <key>CFBundleName</key><string>MacPlay</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key><string>14.6</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppTransportSecurity</key>
  <dict>
    <!-- allow plain HTTP to localhost/local addresses (dev hub);
         production hub is HTTPS on a real domain -->
    <key>NSAllowsLocalNetworking</key><true/>
  </dict>
  <key>NSHumanReadableCopyright</key><string>MacPlay prototype</string>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$APP"
echo "OK: $APP ($VERSION, build $BUILD_NUMBER)"
