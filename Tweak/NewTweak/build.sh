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
  -miphoneos-version-min=15.0 \
  -isysroot "$SDK" \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/MenuTweak.m" \
  -o "$FRAME/libloader"
cp "$ROOT/Info.plist" "$FRAME/Info.plist"
chmod 755 "$FRAME/libloader"
cd "$OUT"
/usr/bin/zip -qry "i3rby_NewTweak_Test.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "i3rby_NewTweak_Test.zip" > SHA256SUMS.txt
file "$FRAME/libloader"
otool -L "$FRAME/libloader"
cat SHA256SUMS.txt
