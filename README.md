# Test

## Aktueller Stand: Absturzdiagnose mit allen Mods

Der Nutzer hat bestätigt, dass die iOSGods-IPA mit **allen bisherigen Mods plus i3rby** erhalten bleiben soll. Ausgangspunkt ist daher wieder die kombinierte Variante: ursprünglicher Ziel-Loader, iGameGod und zusätzlich i3rby. Die isolierte Testversion 2 ist keine gewünschte Ziellösung und bleibt nur als Diagnoseversuch dokumentiert.

Die kombinierte Variante stürzt laut Nutzer ungefähr zwei Sekunden nach dem Start ab. Die genaue Ursache ist noch nicht bestätigt, und eine Reparatur ist noch nicht erfolgt. Für die gezielte Diagnose werden der Geräte-Absturzbericht (`pool…ips`) und das nach dem Umbau verwendete Signierprogramm benötigt. Weitere Änderungen sollen sämtliche bisherigen Mods erhalten.

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

## Einbau in die Ziel-IPA

Der i3rby-Tweak wurde zusätzlich in die bereitgestellte iOSGods-IPA derselben Spielversion eingebaut. Das neue `i3rby.framework` verwendet einen eigenen Namen; die vorhandenen Frameworks bleiben erhalten. Die Ausgabe muss vor der Installation neu signiert werden.

- [Einbau, Signierung und Prüfungen](i3rby-tweak/EINBAU.md)
- [Einbauskript](i3rby-tweak/inject_i3rby.py)
- [Prüfbericht der erzeugten IPA](i3rby-tweak/integration-report.json)
- [Vergleich der Spielprogramme](i3rby-tweak/target-compatibility.json)
