#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/KingMenu.framework"
BIN="$FRAME/KingMenu"
rm -rf "$OUT"
mkdir -p "$FRAME"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"

clang \
  -arch arm64 \
  -dynamiclib \
  -fobjc-arc \
  -miphoneos-version-min=11.0 \
  -isysroot "$SDK" \
  -install_name @rpath/KingMenu.framework/KingMenu \
  -framework UIKit \
  -framework Foundation \
  -framework QuartzCore \
  -framework CoreGraphics \
  "$ROOT/KingMenu.m" \
  -o "$BIN"

cp "$ROOT/Info.plist" "$FRAME/Info.plist"
chmod 755 "$BIN"

cd "$OUT"
/usr/bin/zip -qry "KingMenu_NoAds.zip" "KingMenu.framework"

printf '=== FILE ===\n'
file "$BIN"
printf '\n=== LOAD COMMANDS ===\n'
otool -L "$BIN"
printf '\n=== INSTALL NAME ===\n'
otool -D "$BIN"
printf '\n=== MIN OS ===\n'
otool -l "$BIN" | grep -A3 -E 'LC_VERSION_MIN_IPHONEOS|LC_BUILD_VERSION' || true
printf '\n=== ZIP CONTENTS ===\n'
unzip -l "KingMenu_NoAds.zip"
shasum -a 256 "$BIN" "KingMenu_NoAds.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
