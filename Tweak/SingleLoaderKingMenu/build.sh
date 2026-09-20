#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/libloader.framework"
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
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/Main.m" \
  -framework UIKit \
  -framework Foundation \
  -framework QuartzCore \
  -o "$FRAME/libloader"
cp "$ROOT/../Original-identisch/libloader.framework/Info.plist" "$FRAME/Info.plist"
chmod 755 "$FRAME/libloader"

echo '=== FILE ==='
file "$FRAME/libloader"
echo '=== EXPORT ==='
nm -gU "$FRAME/libloader" | grep iBWuJnPubwtWJIGVxT || true
echo '=== LOAD COMMANDS ==='
otool -L "$FRAME/libloader"
cd "$OUT"
/usr/bin/zip -qry "KingMenu_Single_libloader.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingMenu_Single_libloader.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
