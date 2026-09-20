# Test

## i3rby-Tweak aus 8 Ball Pool

Der originale kompilierte Tweak aus `pool8Signed 2(2).ipa` wurde unverändert extrahiert und byteweise geprüft. Quelle: 8 Ball Pool **56.29.2**, Build **5324**.

- [Original-Tweak als .dylib](i3rby-tweak/i3rby_8BallPool_original.dylib)
- [Vollständiges libloader.framework](i3rby-tweak/libloader.framework)
- [Deutsche Anleitung und Untersuchung](i3rby-tweak/README_DE.md)
- [Technische Analyse](i3rby-tweak/analysis.json)
- [Reproduzierbares Extraktionsskript](i3rby-tweak/extract_tweak.py)
- [SHA-256-Prüfsummen](i3rby-tweak/SHA256SUMS.txt)

Das Framework enthält Hinweise auf `GBModMenu`, `GBPredictionDrawView` und die i3rby-Menüfunktionen. Die `.dylib` ist eine bytegleiche Kopie des Framework-Binaries. Der ursprüngliche Tweak-Quelltext wurde nicht wiederhergestellt; der Python-Code dient ausschließlich zur Extraktion.

Ein erneuter Einbau benötigt passende Ladepfade und eine gültige iOS-Signierung. Ein Funktionstest auf einem iPhone wurde nicht durchgeführt.
