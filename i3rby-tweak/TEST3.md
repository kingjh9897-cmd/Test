# Testversion 3: alle bisherigen Mods behalten + i3rby am Originalpfad

Ziel dieser Variante ist ausdrücklich **nicht**, iGameGod oder den vorhandenen iOSGods-Loader zu entfernen. Die komplette bestehende Ziel-IPA bleibt Ausgangspunkt. Gleichzeitig bekommt i3rby wieder den Pfad und die Binäridentität, unter denen der Tweak ursprünglich gefunden wurde.

## Warum diese Variante

Die erste kombinierte Variante hat i3rby als zusätzliches `i3rby.framework` eingebaut und dabei den internen Installationsnamen geändert. Laut Nutzer beendet sich die App ungefähr zwei Sekunden nach dem Start. Ohne Geräte-Absturzbericht ist die Ursache nicht bestätigt.

Test 3 verändert deshalb die Aufteilung:

- `iGameGod.framework` bleibt erhalten.
- Der vorhandene iOSGods-`libloader.framework` bleibt funktional erhalten, wird aber nach `Frameworks/lg.framework/` verschoben.
- Sein Binary heißt weiterhin `libloader`; nur sein Framework-Pfad und `LC_ID_DYLIB` werden auf den neuen Pfad angepasst.
- Das originale i3rby-Binary wird **bytegleich** wieder unter `Frameworks/libloader.framework/libloader` eingesetzt.
- i3rbys ursprünglicher Installationsname `@rpath/libloader.framework/libloader` bleibt unverändert.
- Im Hauptprogramm wird der bisherige iOSGods-Loader auf den neuen Pfad umgestellt und zusätzlich ein Ladebefehl für i3rby am ursprünglichen Pfad eingefügt.
- Falls andere Mach-O-Dateien in der Ziel-IPA direkt auf den alten iOSGods-Loaderpfad zeigen, werden diese Verweise ebenfalls auf den neuen Pfad umgestellt.
- Alte Framework-CodeSignatures werden nicht als gültig behandelt. Die komplette Ausgabe muss neu signiert werden.

## Erstellen

```bash
python3 i3rby-tweak/build_test3_keep_all_mods.py \
  "8 Ball Pool v56.29.2 Signed by iOSGods 2.ipa" \
  --out "8BallPool_i3rby_Test3_all_mods_neu_signieren.ipa"
```

Das Skript akzeptiert nur die bereits untersuchte Ziel-IPA mit SHA-256:

`27500e6357fc4b215f70f7df1379b29bd921fc2b6cb62d0b6c56302e260ee698`

Für das originale i3rby-Binary wird weiterhin diese SHA-256 erwartet:

`d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb`

Neben der IPA wird automatisch ein JSON-Prüfbericht erzeugt. Darin stehen unter anderem die geänderten Ladepfade, die endgültige Ausgabe-Prüfsumme und ob weitere Binärdateien auf den alten Loaderpfad verwiesen haben.

## Wichtig

Diese Variante ist statisch geprüft, aber noch nicht auf einem iPhone ausgeführt. Sie ist deshalb keine bestätigte Reparatur. Wenn die App weiterhin kurz nach dem Start beendet wird, ist der Geräte-Absturzbericht (`.ips`) der nächste entscheidende Schritt. Besonders wichtig sind `Exception Type`, `Termination Reason`, `Application Specific Information`, der abstürzende Thread und die geladenen Images.
