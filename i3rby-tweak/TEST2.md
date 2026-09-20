# Testversion 2: i3rby allein unter dem ursprünglichen Pfad

Status: Der Nutzer meldet einen Absturz der ersten kombinierten Variante etwa zwei Sekunden nach dem Start. Ein Geräte-Absturzbericht liegt noch nicht vor. Die genaue Ursache ist unbestätigt. Diese zweite Variante dient dazu, die Kombination mehrerer Mods und den geänderten i3rby-Dateipfad als mögliche Einflussfaktoren einzugrenzen.

## Geändert

- Ausgangspunkt ist wieder die unveränderte bereitgestellte iOSGods-Ziel-IPA 56.29.2 / Build 5324.
- Das bisherige iOSGods-`libloader.framework` wurde durch das extrahierte i3rby-Framework ersetzt.
- i3rby liegt wieder an seinem ursprünglichen Pfad `Frameworks/libloader.framework/libloader`.
- Der i3rby-Binärcode und seine `Info.plist` sind exakt mit dem extrahierten Original identisch. Es wurde kein interner Installationsname geändert.
- `iGameGod.framework` und sein Ladebefehl wurden entfernt. Es gibt kein zusätzliches `i3rby.framework`.
- Der Spielcode sowie alle Abschnittsadressen und -größen bleiben gegenüber der Ziel-IPA erhalten. Die bereits vorhandenen Codeunterschiede zur ursprünglichen i3rby-Quell-IPA wurden nicht verändert.

## Ausgabe

`8BallPool_i3rby_Test2_neu_signieren.ipa` — 86122345 Bytes.

SHA-256: `afbf877b6786f908dc5f58982fceaabc280fad2b2906b45e27c54bc9b31a43a3`.

Die IPA muss einschließlich des eingebetteten i3rby-Frameworks neu signiert werden. Es wurde keine Signierung durchgeführt. Die alte App-Signatur gilt nach den Änderungen nicht mehr. Die neue Variante wurde hier nicht auf einem iPhone gestartet; sie ist keine bestätigte Behebung des Absturzes.

## Prüfung

Alle ausgegebenen ZIP-Einträge wurden erneut gelesen und anhand ihrer CRCs und SHA-256-Prüfsummen geprüft. 3204 beibehaltene Einträge wurden verifiziert. Am Spielprogramm wurde ausschließlich der iGameGod-Ladebefehl aus der Load-Command-Tabelle entfernt und deren Zähler/Größe angepasst. Sämtliche übrigen Dateibereiche und Ladebefehle wurden geprüft.

## Erneut erstellen

```bash
python3 i3rby-tweak/build_i3rby_isolated.py \
  "8 Ball Pool v56.29.2 Signed by iOSGods 2.ipa" \
  --out "8BallPool_i3rby_Test2_neu_signieren.ipa"
```

Benötigt werden Python 3, das danebenliegende `extract_tweak.py`, der Originalordner `libloader.framework` und genau die ursprüngliche Ziel-IPA. Das Skript prüft die Eingabeprüfsummen und überschreibt keine bestehenden Ausgabedateien.

## Wenn der Start weiterhin scheitert

Zur nächsten Diagnose werden der neue Geräte-Absturzbericht (`.ips`) und der Name des verwendeten Signierprogramms benötigt. Besonders relevant sind `Exception Type`, `Termination Reason`, `Application Specific Information`, der abstürzende Thread und die Liste der geladenen Module. Ein Signatur- oder Bibliotheksladefehler ist damit von einem Absturz während der Tweak-Initialisierung zu unterscheiden.
