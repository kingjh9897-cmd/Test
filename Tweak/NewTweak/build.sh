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
  echo '=== SHA256 / SIZE ==='
  shasum -a 256 "$ORIG" "$NEW"
  ls -l "$ORIG" "$NEW"
  echo
  echo '=== FILE ==='
  file "$ORIG"
  file "$NEW"
  echo
  echo '=== LIPO ==='
  lipo -info "$ORIG" || true
  lipo -info "$NEW" || true
  echo
  echo '=== MACH HEADER ORIGINAL ==='
  otool -hv "$ORIG" || true
  echo '=== MACH HEADER NEW ==='
  otool -hv "$NEW" || true
  echo
  echo '=== DEPENDENCIES ORIGINAL ==='
  otool -L "$ORIG" || true
  echo '=== DEPENDENCIES NEW ==='
  otool -L "$NEW" || true
  echo
  echo '=== BUILD VERSION / MIN OS ORIGINAL ==='
  xcrun vtool -show-build "$ORIG" || true
  echo '=== BUILD VERSION / MIN OS NEW ==='
  xcrun vtool -show-build "$NEW" || true
  echo
  echo '=== EXPORTED SYMBOL COUNT ==='
  printf 'original: '; nm -gjU "$ORIG" 2>/dev/null | wc -l || true
  printf 'new: '; nm -gjU "$NEW" 2>/dev/null | wc -l || true
  echo
  echo '=== ORIGINAL EXPORTED SYMBOLS (first 250) ==='
  nm -gjU "$ORIG" 2>/dev/null | head -250 || true
  echo
  echo '=== NEW EXPORTED SYMBOLS ==='
  nm -gjU "$NEW" 2>/dev/null || true
  echo
  echo '=== ORIGINAL OBJC CLASS EXPORTS ==='
  nm -gjU "$ORIG" 2>/dev/null | egrep '^_OBJC_(CLASS|METACLASS)_\$_' | head -200 || true
  echo
  echo '=== CODESIGN ORIGINAL ==='
  codesign -dvvv "$ORIG" 2>&1 || true
  echo '=== CODESIGN NEW ==='
  codesign -dvvv "$NEW" 2>&1 || true
} | tee "$REPORT"

cd "$OUT"
/usr/bin/zip -qry "KingTweak_NoOp_Diagnostic.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_NoOp_Diagnostic.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
