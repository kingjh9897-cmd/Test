#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist"
FRAME="$OUT/KingMenuPresence.framework"
BIN="$FRAME/KingMenuPresence"
rm -rf "$OUT"
mkdir -p "$FRAME"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
clang -arch arm64 -dynamiclib -fvisibility=hidden -miphoneos-version-min=11.0 -isysroot "$SDK" \
  -install_name @rpath/KingMenuPresence.framework/KingMenuPresence \
  "$ROOT/PresenceOnly.c" -o "$BIN"
cp "$ROOT/Info.plist" "$FRAME/Info.plist"
chmod 755 "$BIN"
cd "$OUT"
/usr/bin/zip -qry KingMenuPresence_Diagnostic.zip KingMenuPresence.framework
shasum -a 256 "$BIN" KingMenuPresence_Diagnostic.zip > SHA256SUMS.txt
cat SHA256SUMS.txt
