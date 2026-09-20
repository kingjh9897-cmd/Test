# i3rby in die Ziel-IPA eingebaut

Die Datei `8BallPool_56.29.2_i3rby_neu_signieren.ipa` wurde aus der angehängten Ziel-IPA erstellt. Der Einbau ist abgeschlossen; vor der Installation ist eine neue Signierung erforderlich.

## Ergebnis

- Ziel: 8 Ball Pool **56.29.2**, Build **5324**.
- Neues Framework: `Payload/pool.app/Frameworks/i3rby.framework/`.
- Das Hauptprogramm lädt `@executable_path/Frameworks/i3rby.framework/i3rby`.
- Das neue Framework verwendet die eigene Kennung `local.extracted.i3rby` und den Installationsnamen `@rpath/i3rby.framework/i3rby`.
- Die vorhandenen Frameworks `libloader` und `iGameGod` sind erhalten.
- Der ursprüngliche i3rby-Code ist erhalten. Am Tweak-Binary wurde ausschließlich das Installationsnamenfeld angepasst.
- Am Hauptprogramm wurden ausschließlich die zwei Header-Zähler und 80 zuvor leere Bytes für einen neuen Ladebefehl geändert.

## Verwenden

1. Die fertige IPA in dein iOS-Signierprogramm importieren.
2. Die gesamte App einschließlich eingebetteter Frameworks und Erweiterungen mit einer für dein Gerät geeigneten Signierung neu signieren.
3. Die neu signierte IPA installieren und starten.

Eine Signierung wurde hier nicht durchgeführt. Die zuvor enthaltene Signatur ist durch die Änderung ungültig. Ein Funktionstest auf einem iPhone steht aus.

## Geprüft

Alle 3224 ursprünglichen ZIP-Einträge wurden nach dem Verpacken erneut gelesen und mit der Vorlage verglichen. Abgesehen vom geänderten Hauptprogramm stimmen die entpackten Dateiinhalte exakt überein. Beide neuen Framework-Dateien wurden byteweise geprüft; beim Lesen aller Dateien wurden auch die CRC-Prüfsummen kontrolliert.

Die Code- und Datenpositionen im Hauptprogramm sind unverändert. Die definierten Objective-C-Klassen des eingefügten Tweaks kollidierten bei der statischen Prüfung nicht mit denen des Ziel-Hauptprogramms, des alten `libloader` oder von `iGameGod`.

Das Hauptprogramm der Ziel-IPA und das der ursprünglichen Tweak-IPA verwenden die gleichen Positionen und Größen für alle 27 `__TEXT`-Sektionen. 26 dieser Sektionen sind bytegleich. In der eigentlichen Code-Sektion unterscheiden sich bereits die beiden Eingaben an 153 Bytes; diese vorhandenen Unterschiede wurden beibehalten.

Diese Dateiprüfungen beweisen keine konfliktfreie Zusammenarbeit der Tweaks zur Laufzeit. Bereits im Tweak vorhandene Freischaltungs- oder Serverabhängigkeiten bleiben bestehen.

## Einbau reproduzieren

`inject_i3rby.py` benötigt das danebenliegende `extract_tweak.py` und das bereits extrahierte `libloader.framework`. Python 3 mit Standardbibliothek genügt:

```bash
python3 i3rby-tweak/inject_i3rby.py \
  "8 Ball Pool v56.29.2 Signed by iOSGods 2.ipa" \
  --out "8BallPool_56.29.2_i3rby_neu_signieren.ipa"
```

Das Skript überschreibt keine bestehende Ausgabedatei. Es prüft den bekannten Tweak-Hash, Spielversion und Build, lehnt einen bereits vorhandenen i3rby-Ladeeintrag ab und bricht bei unzureichendem leeren Header-Padding ab. Es verschiebt keine Spielsektionen.

## Dateien und Prüfsumme

- `integration-report.json`: konkrete Einbau- und Integritätsprüfung.
- `target-compatibility.json`: Vergleich der beiden Spielprogramme.
- Ausgabegröße: 95650148 Bytes.
- Ausgabe-SHA-256: `5e8336ffe6c8f306b973feecb1b72ff4d781ad06d75271252d0cfd05f9e6854e`.

Technische Referenzen: [Apple: Frameworks einbetten und Ladepfade prüfen](https://developer.apple.com/library/archive/technotes/tn2435/_index.html) und [Apple: Mach-O-Strukturen](https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/loader.h).
