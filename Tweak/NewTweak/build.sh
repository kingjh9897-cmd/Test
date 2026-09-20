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
  echo '=== SELECTED LOAD COMMANDS ORIGINAL ==='
  otool -l "$ORIG" | egrep -A8 'LC_ID_DYLIB|LC_BUILD_VERSION|LC_VERSION_MIN_IPHONEOS|LC_CODE_SIGNATURE|LC_ENCRYPTION_INFO|LC_DYLD_INFO|LC_DYLD_CHAINED_FIXUPS' || true
  echo '=== SELECTED LOAD COMMANDS NEW ==='
  otool -l "$NEW" | egrep -A8 'LC_ID_DYLIB|LC_BUILD_VERSION|LC_VERSION_MIN_IPHONEOS|LC_CODE_SIGNATURE|LC_ENCRYPTION_INFO|LC_DYLD_INFO|LC_DYLD_CHAINED_FIXUPS' || true
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
