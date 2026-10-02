#!/bin/bash
# Package dist/MacPlay.app (from ./build.sh) as dist/MacPlay-<version>.dmg with an
# Applications link to drag it onto, plus a SHA-256 file to check the download.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${1:?usage: ./make_dmg.sh <version>}"
APP="dist/MacPlay.app"
[ -d "$APP" ] || { echo "Build the app first: ./build.sh" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/MacPlay.app"
ln -s /Applications "$STAGE/Applications"

DMG="MacPlay-$VERSION.dmg"
hdiutil create -volname "MacPlay $VERSION" -srcfolder "$STAGE" -format UDZO -ov "dist/$DMG"
(cd dist && shasum -a 256 "$DMG" > "$DMG.sha256")
echo "OK: dist/$DMG"
