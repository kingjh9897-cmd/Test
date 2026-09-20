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
  -miphoneos-version-min=11.0 \
  -isysroot "$SDK" \
  -install_name @rpath/libloader.framework/libloader \
  "$ROOT/NoOpTweak.c" \
  -o "$NEW"
cp "$ROOT/../Original-identisch/libloader.framework/Info.plist" "$FRAME/Info.plist"
chmod 755 "$NEW"

REPORT="$OUT/STRUCTURE_COMPARE.txt"
{
  echo '=== REQUIRED EXPORT DETAIL ==='
  nm -gU "$ORIG" | grep 'iBWuJnPubwtWJIGVxT' || true
  nm -m "$ORIG" | grep 'iBWuJnPubwtWJIGVxT' || true
  xcrun dyld_info -exports "$ORIG" 2>/dev/null | grep -A3 -B3 'iBWuJnPubwtWJIGVxT' || true
  echo
  echo '=== NEW EXPORT DETAIL ==='
  nm -gU "$NEW" || true
  xcrun dyld_info -exports "$NEW" 2>/dev/null || true
  echo
  echo '=== ORIGINAL LOADS ==='
  otool -L "$ORIG" || true
} | tee "$REPORT"

cd "$OUT"
/usr/bin/zip -qry "KingTweak_NoOp_Diagnostic.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_NoOp_Diagnostic.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
