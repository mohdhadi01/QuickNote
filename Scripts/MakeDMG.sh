#!/bin/bash
# Builds the shareable QuickNote DMG from the Release build.
# Usage: Scripts/MakeDMG.sh
set -euo pipefail

cd "$(dirname "$0")/.."

APP_DERIVED="$HOME/Library/Developer/Xcode/DerivedData/QuickNote-*/Build/Products/Release/QuickNote.app"
APP=$(ls -d $APP_DERIVED 2>/dev/null | head -1)
if [ -z "$APP" ]; then
    echo "Release build not found. Run:" >&2
    echo "  xcodebuild -project QuickNote.xcodeproj -scheme QuickNote -configuration Release build" >&2
    exit 1
fi

SIGN_IDENTITY="${SIGN_IDENTITY:-Apple Development: Mohd Hadi (4QCYHQS6Q5)}"
VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)
OUT_DIR="dist"
DMG="$OUT_DIR/QuickNote-$VERSION.dmg"
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

mkdir -p "$OUT_DIR"

cat > "$STAGING/INSTALL.txt" <<'EOF'
QuickNote 1.0 — instant notes for macOS
========================================

Capture a thought from anywhere: press Control+Shift+Space,
type, press Return. The note is saved on your Mac — nothing leaves it.

WHAT'S INSIDE
-------------
- QuickNote.app     the app (Apple Silicon + Intel)
- Applications      drag target for installing

INSTALL
-------
1. Drag QuickNote onto the Applications folder icon.
2. Open QuickNote from your Applications folder or Launchpad.

FIRST LAUNCH (one time)
-----------------------
macOS may say the app "cannot be verified" because it isn't sold through
the App Store. It is safe — it only stores notes on this Mac.

- Click "Done" on the warning, then open
  System Settings → Privacy & Security → scroll down → "Open Anyway".
- Or in Terminal:  xattr -cr /Applications/QuickNote.app

TIP
---
- Enable "Launch at Login" in the menu bar icon or Settings > General,
  so the capture shortcut is always available.
- Close the window any time — the menu bar icon and the capture
  shortcut keep working.
- Change the shortcut in Settings > Quick Capture.

PRIVACY
-------
No account. No cloud. No telemetry. Notes live in your local library.
EOF

echo "→ Signing ($SIGN_IDENTITY)"
codesign --force --options runtime \
    --entitlements QuickNote/QuickNote.entitlements \
    --sign "$SIGN_IDENTITY" "$APP"

echo "→ Staging"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "→ Building $DMG"
hdiutil create -volname "QuickNote" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null

echo "→ Verifying"
codesign --verify --deep --strict "$APP" && echo "   signature OK"
hdiutil attach "$DMG" -mountpoint /tmp/quicknote-dmg-verify -nobrowse -quiet
ls /tmp/quicknote-dmg-verify
hdiutil detach /tmp/quicknote-dmg-verify -quiet

echo "✓ $DMG"
