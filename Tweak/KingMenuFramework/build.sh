#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/KingMenu.framework"

rm -rf "$OUT"
mkdir -p "$FRAME"

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
clang \
  -arch arm64 \
  -dynamiclib \
  -fobjc-arc \
  -fblocks \
  -miphoneos-version-min=11.0 \
  -isysroot "$SDK" \
  -install_name @rpath/KingMenu.framework/KingMenu \
  "$ROOT/Main.m" \
  -framework UIKit \
  -framework Foundation \
  -framework QuartzCore \
  -framework CoreGraphics \
  -o "$FRAME/KingMenu"

cp "$ROOT/Info.plist" "$FRAME/Info.plist"
chmod 755 "$FRAME/KingMenu"

file "$FRAME/KingMenu"
otool -L "$FRAME/KingMenu"

cd "$OUT"
/usr/bin/zip -qry "KingMenu.framework.zip" "KingMenu.framework"
shasum -a 256 "$FRAME/KingMenu" "KingMenu.framework.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
