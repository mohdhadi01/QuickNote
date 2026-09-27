#!/bin/bash
# Builds the shareable QuickNote DMG from the Release build.
#
# Plain:            Scripts/MakeDMG.sh
# Notarized:        SIGN_IDENTITY="Developer ID Application: NAME (TEAMID)" \
#                   NOTARIZE_APPLE_ID=you@example.com \
#                   NOTARIZE_PASSWORD=app-specific-password \
#                   NOTARIZE_TEAM_ID=TEAMID \
#                   Scripts/MakeDMG.sh
#
# Notarization requires a paid Apple Developer Program membership
# ($99/yr). Without it the DMG still builds, but every Mac will show the
# one-time Gatekeeper "Open Anyway" prompt on first launch.
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
RW_DMG="$OUT_DIR/QuickNote-$VERSION-rw.dmg"
STAGING=$(mktemp -d)
VOL_NAME="QuickNote"
trap 'rm -rf "$STAGING"; hdiutil detach "/Volumes/$VOL_NAME" -force -quiet >/dev/null 2>&1 || true' EXIT

mkdir -p "$OUT_DIR"

cat > "$STAGING/INSTALL.txt" <<'EOF'
QuickNote, instant notes for macOS
====================================

Capture a thought from anywhere: press Control+Shift+Space,
type, press Return. The note is saved on your Mac, nothing leaves it.

INSTALL
-------
Drag QuickNote onto the Applications folder icon on the right.

FIRST LAUNCH (one time)
-----------------------
Because this build isn't notarized yet, macOS shows a one-time warning:
"Apple could not verify QuickNote". It is safe. It has no network
access and stores notes only on this Mac.

1. Click "Done" on the warning.
2. Open System Settings → Privacy & Security → scroll down →
   click "Open Anyway" → "Open".

(Terminal alternative:  xattr -cr /Applications/QuickNote.app)

TIP
---
- Enable "Launch at Login" in the menu bar icon or Settings > General.
- Close the window any time. The menu bar icon and the capture
  shortcut keep working.
- Change the shortcut in Settings > Quick Capture.
EOF

echo "→ Signing ($SIGN_IDENTITY)"
codesign --force --options runtime \
    --entitlements QuickNote/QuickNote.entitlements \
    --sign "$SIGN_IDENTITY" "$APP"

echo "→ Staging"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
mkdir -p "$STAGING/.background"
swift Scripts/dmg-background.swift "$STAGING/.background/background.png"

echo "→ Building read-write image for layout"
rm -f "$RW_DMG"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING" -ov -format UDRW -size 200m "$RW_DMG" >/dev/null
hdiutil attach "$RW_DMG" -nobrowse -noautoopen -quiet
ls "/Volumes/$VOL_NAME/" && ls "/Volumes/$VOL_NAME/.background/"

echo "→ Laying out installer window"
LAYOUT_OK=1
if ! osascript <<'APPLESCRIPT'
tell application "Finder"
    tell disk "QuickNote"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 160, 860, 580}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set text size of theViewOptions to 13
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "QuickNote.app" of container window to {185, 225}
        set position of item "Applications" of container window to {475, 225}
        set position of item "INSTALL.txt" of container window to {330, 375}
        close
    end tell
end tell
APPLESCRIPT
then
    LAYOUT_OK=0
    echo "   background step failed, retrying without the background picture"
    osascript <<'APPLESCRIPT' || LAYOUT_OK=0
tell application "Finder"
    tell disk "QuickNote"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 160, 860, 580}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set text size of theViewOptions to 13
        set position of item "QuickNote.app" of container window to {185, 225}
        set position of item "Applications" of container window to {475, 225}
        set position of item "INSTALL.txt" of container window to {330, 375}
        close
    end tell
end tell
APPLESCRIPT
fi
[ "$LAYOUT_OK" -eq 1 ] && echo "   layout applied" || echo "   ⚠︎ layout skipped (Finder automation not approved)"

echo "→ Compressing"
sync
sleep 1
DETACHED=0
for _ in 1 2 3 4; do
    if hdiutil detach "/Volumes/$VOL_NAME" -quiet >/dev/null 2>&1; then DETACHED=1; break; fi
    sleep 2
    hdiutil detach "/Volumes/$VOL_NAME" -force -quiet >/dev/null 2>&1 || true
done
[ "$DETACHED" -eq 1 ] || { echo "   ⚠︎ could not detach /Volumes/$VOL_NAME"; exit 1; }
sleep 3   # let diskimages-helper release the file before convert
rm -f "$DMG"
CONVERTED=0
for _ in 1 2 3; do
    if hdiutil convert "$RW_DMG" -format UDZO -o "$DMG" >/dev/null 2>&1; then CONVERTED=1; break; fi
    sleep 3
done
[ "$CONVERTED" -eq 1 ] || { echo "   ⚠︎ could not compress the image"; exit 1; }
rm -f "$RW_DMG"

NOTARIZE_ARGS=()
[ -n "${NOTARIZE_APPLE_ID:-}" ] && NOTARIZE_ARGS+=(--apple-id "$NOTARIZE_APPLE_ID")
[ -n "${NOTARIZE_PASSWORD:-}" ] && NOTARIZE_ARGS+=(--password "$NOTARIZE_PASSWORD")
[ -n "${NOTARIZE_TEAM_ID:-}" ] && NOTARIZE_ARGS+=(--team-id "$NOTARIZE_TEAM_ID")

if [ ${#NOTARIZE_ARGS[@]} -eq 3 ]; then
    echo "→ Notarizing (this can take a few minutes)"
    xcrun notarytool submit "$DMG" "${NOTARIZE_ARGS[@]}" --wait
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
else
    echo "   ℹ︎ Not notarized. First launch needs Open Anyway (see INSTALL.txt)."
    echo "     To ship without Gatekeeper warnings, enroll in the Apple Developer"
    echo "     Program and re-run with a Developer ID identity + NOTARIZE_* env vars."
fi

echo "→ Verifying"
codesign --verify --deep --strict "$APP" && echo "   signature OK"
hdiutil attach "$DMG" -mountpoint /tmp/quicknote-dmg-verify -nobrowse -quiet
ls /tmp/quicknote-dmg-verify
hdiutil detach /tmp/quicknote-dmg-verify -quiet

echo "✓ $DMG"
