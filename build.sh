#!/bin/bash
# Builds LiveWallpaper.app — a double-clickable macOS app bundle.
set -e

CONFIG=release
APP="LiveWallpaper.app"

echo "==> Compiling ($CONFIG)…"
swift build -c "$CONFIG"
BIN_PATH=$(swift build -c "$CONFIG" --show-bin-path)

echo "==> Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/LiveWallpaper" "$APP/Contents/MacOS/LiveWallpaper"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "   (codesign skipped)"

echo ""
echo "Done. Launch with:  open $APP"
