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
  -fobjc-arc \
  -fvisibility=hidden \
  -miphoneos-version-min=9.0 \
  -isysroot "$SDK" \
  -framework UIKit \
  -framework Foundation \
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/CompatibilityUIApplicationMain.m" \
  -o "$NEW"
cp "$ROOT/../Original-identisch/libloader.framework/Info.plist" "$FRAME/Info.plist"
chmod 755 "$NEW"

echo '=== EXPORT CHECK ==='
nm -gU "$ORIG" | grep 'iBWuJnPubwtWJIGVxT'
nm -gU "$NEW" | grep 'iBWuJnPubwtWJIGVxT'
echo '=== NEW DEPENDENCIES ==='
otool -L "$NEW"
echo '=== NEW MIN OS ==='
xcrun vtool -show-build "$NEW" || true

cd "$OUT"
/usr/bin/zip -qry "KingTweak_UIApplicationMain_Compat.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_UIApplicationMain_Compat.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
