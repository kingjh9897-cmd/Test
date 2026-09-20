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
  -miphoneos-version-min=11.0 \
  -isysroot "$SDK" \
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/NoOpTweak.c" \
  -o "$FRAME/libloader"
cp "$ROOT/../Original-identisch/libloader.framework/Info.plist" "$FRAME/Info.plist"
chmod 755 "$FRAME/libloader"
cd "$OUT"
/usr/bin/zip -qry "KingTweak_NoOp_Diagnostic.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_NoOp_Diagnostic.zip" > SHA256SUMS.txt
file "$FRAME/libloader"
otool -L "$FRAME/libloader"
cat SHA256SUMS.txt
