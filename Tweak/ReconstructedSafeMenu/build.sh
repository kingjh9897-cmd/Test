#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/KingReconstructed.framework"

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
  -install_name @rpath/KingReconstructed.framework/KingReconstructed \
  "$ROOT/Main.m" \
  -framework UIKit \
  -framework Foundation \
  -framework QuartzCore \
  -framework CoreGraphics \
  -o "$FRAME/KingReconstructed"

cp "$ROOT/Info.plist" "$FRAME/Info.plist"
chmod 755 "$FRAME/KingReconstructed"

file "$FRAME/KingReconstructed"
otool -L "$FRAME/KingReconstructed"

cd "$OUT"
/usr/bin/zip -qry "KingReconstructed.framework.zip" "KingReconstructed.framework"
shasum -a 256 "$FRAME/KingReconstructed" "KingReconstructed.framework.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
