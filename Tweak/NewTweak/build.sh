#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/libloader.framework"
ORIG="$ROOT/../Original-identisch/libloader.framework/libloader"
NEW="$FRAME/libloader"
rm -rf "$OUT"
mkdir -p "$FRAME"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
clang \
  -arch arm64 \
  -dynamiclib \
  -fvisibility=hidden \
  -miphoneos-version-min=11.0 \
  -isysroot "$SDK" \
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/CompatibilityTweak.c" \
  -o "$NEW"
cp "$ROOT/../Original-identisch/libloader.framework/Info.plist" "$FRAME/Info.plist"
chmod 755 "$NEW"

# Verify the generated dylib exports the exact symbol used by the working original.
echo '=== ORIGINAL EXPORT ==='
nm -gU "$ORIG" | grep 'iBWuJnPubwtWJIGVxT'
echo '=== GENERATED EXPORT ==='
nm -gU "$NEW" | grep 'iBWuJnPubwtWJIGVxT'

echo '=== GENERATED MACH-O ==='
file "$NEW"
otool -L "$NEW"

cd "$OUT"
/usr/bin/zip -qry "KingTweak_Compatibility_Test.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_Compatibility_Test.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
