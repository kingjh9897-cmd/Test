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

echo '=== ORIGINAL EXPORT ==='
nm -gU "$ORIG" | grep 'iBWuJnPubwtWJIGVxT' || true

echo '=== ORIGINAL FUNCTION DISASSEMBLY: OTOOL -p ==='
otool -tvV -p iBWuJnPubwtWJIGVxT "$ORIG" 2>&1 | head -n 160 || true

echo '=== ORIGINAL FUNCTION DISASSEMBLY: LLVM OBJDUMP ==='
xcrun llvm-objdump --macho --disassemble "$ORIG" 2>&1 | grep -A120 -B5 'iBWuJnPubwtWJIGVxT' || true

echo '=== RAW BYTES AROUND 0x108A0 ==='
otool -s __TEXT __text "$ORIG" 2>&1 | head -n 120 || true

echo '=== GENERATED EXPORT ==='
nm -gU "$NEW" | grep 'iBWuJnPubwtWJIGVxT' || true

cd "$OUT"
/usr/bin/zip -qry "KingTweak_Compatibility_Test.zip" "libloader.framework"
shasum -a 256 "$FRAME/libloader" "KingTweak_Compatibility_Test.zip" > SHA256SUMS.txt
cat SHA256SUMS.txt
