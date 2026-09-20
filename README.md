# Test

## Aktueller Stand: Testversion 3 mit allen Mods

Der Nutzer hat bestätigt, dass die iOSGods-IPA mit **allen bisherigen Mods plus i3rby** erhalten bleiben soll. Deshalb bleibt `iGameGod.framework` erhalten und die bestehende Ziel-IPA wird nicht auf die isolierte Test-2-Variante reduziert.

Für **Test 3** wird der vorhandene iOSGods-Loader auf einen eigenen Framework-Pfad verschoben. Dadurch kann das originale i3rby-Binary wieder unter seinem ursprünglichen Pfad `Frameworks/libloader.framework/libloader` und mit seinem unveränderten Installationsnamen geladen werden. Die Ausgabe muss anschließend vollständig neu signiert werden.

- [Testversion 3: Aufbau und Diagnose](i3rby-tweak/TEST3.md)
- [Test-3-Buildskript](i3rby-tweak/build_test3_keep_all_mods.py)
- [Frühere isolierte Testversion 2](i3rby-tweak/TEST2.md)

Die Ursache des gemeldeten Absturzes ungefähr zwei Sekunden nach dem Start ist ohne Geräte-Absturzbericht weiterhin nicht bestätigt. Test 3 ist daher eine neue Diagnosevariante und noch kein bestätigter Runtime-Fix.

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

## Erste kombinierte Einbauvariante

Der i3rby-Tweak wurde zusätzlich in die bereitgestellte iOSGods-IPA derselben Spielversion eingebaut. Diese erste Variante verwendete ein eigenes `i3rby.framework`; laut Nutzer stürzt sie ungefähr zwei Sekunden nach dem Start ab.

- [Einbau, Signierung und Prüfungen](i3rby-tweak/EINBAU.md)
- [Einbauskript](i3rby-tweak/inject_i3rby.py)
- [Prüfbericht der erzeugten IPA](i3rby-tweak/integration-report.json)
- [Vergleich der Spielprogramme](i3rby-tweak/target-compatibility.json)
