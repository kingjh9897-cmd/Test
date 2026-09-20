# i3rby-Tweak aus 8 Ball Pool – Originalextraktion

Der kompilierte Tweak wurde unverändert aus der hochgeladenen IPA herausgelöst.

## Dateien

- `i3rby_8BallPool_original.dylib`: unveränderte Kopie des originalen Framework-Binaries. Nur der Dateiname hat die Endung `.dylib` erhalten.
- `libloader.framework/`: vollständiges originales Framework einschließlich `Info.plist` und vorhandenem `_CodeSignature/CodeResources`.
- `analysis.json`: maschinenlesbare Untersuchung von App und Tweak, Ladebefehle, Abhängigkeiten, Klassen, Symbolnamen, Marker-Offsets und Prüfsummen.
- `extract_tweak.py`: ausführbarer Python-Quelltext für die reproduzierbare Extraktion. Dies ist der Quelltext des Extraktionswerkzeugs, nicht der ursprüngliche Tweak-Quelltext.
- `SHA256SUMS.txt`: Prüfsummen der mitgelieferten Dateien, ohne diese Prüfsummendatei selbst.

## Ergebnis der Untersuchung

| Merkmal | Ergebnis |
| --- | --- |
| Quelle | `pool8Signed 2(2).ipa` |
| Spiel | 8 Ball Pool 56.29.2, Build 5324 |
| Bundle-ID | `com.miniclip.8ballpoolmult` |
| Fundort | `Payload/pool.app/Frameworks/libloader.framework/libloader` |
| Größe des Tweak-Binaries | 10,116,480 Bytes |
| Architektur / Dateityp | ARM64 / Mach-O `MH_DYLIB` |
| Verschlüsselungsfeld | `LC_ENCRYPTION_INFO_64.cryptid = 0` |
| Code-Sektion `__text` | 8.039.692 Bytes |
| Einträge in `LC_FUNCTION_STARTS` | 5741 |
| Definierte Objective-C-Klassen | 34 |
| Symboltabelle | 552 Einträge: 550 undefinierte Import-Symbole, 2 übrige Einträge |
| SHA-256 des Tweak-Binaries | `d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb` |
| SHA-256 der Quell-IPA | `3fc6595c83a6c79fcaf3dbcce388fc8b97c3f9a00575607c6711517ff2ec7a54` |

In dieser IPA wurden 29 Mach-O-Dateien anhand ihrer Dateikennung erkannt und durchsucht. Die vier geprüften Identifikationsmarker `GBModMenu`, `GBPredictionDrawView`, `com.i3rby.8poolmod` und `Prediction Lines` fanden sich ausschließlich in `libloader.framework/libloader`. Zusätzlich enthält diese Datei Menütexte wie `Pocket Rings`, `Scratch Alert`, `Stream Proof`, `Auto Select Pocket`, `Aim Mode`, `Humanization` und `Break Mode`. Diese Befunde zusammen mit Code und Klassen belegen, dass das Framework Tweak-Code enthält. Eine vollständige Funktionsprüfung wurde damit nicht durchgeführt.

Der ursprüngliche Code ist kompiliert; viele Klassen- und Funktionsnamen sind verschleiert oder entfernt. Die Extraktion stellt weder das originale Xcode-/Theos-Projekt noch ursprüngliche Objective-C-/C++-Quelldateien wieder her.

## Laden und Einbauen

Das Hauptprogramm `pool` enthält bereits diesen `LC_LOAD_DYLIB`-Eintrag:

```text
@executable_path/Frameworks/libloader.framework/libloader
```

Die Bibliothek identifiziert sich über `LC_ID_DYLIB` als:

```text
@rpath/libloader.framework/libloader
```

Der einfachste Weg, die vorhandene Struktur zu erhalten, ist das vollständige Framework an genau seinem ursprünglichen Pfad. Die zusätzlich angebotene `.dylib` ist bytegleich; ihr interner Installationsname wurde nicht auf den neuen Dateinamen geändert. Ein Import als einzelne `.dylib` muss den tatsächlichen Ladepfad berücksichtigen.

Die direkten Ladebefehle des Tweaks nennen Apple-Systemframeworks und Swift-Laufzeitbibliotheken. Es gibt außerdem Imports für `dlopen` und `dlsym`. Deshalb schließt die Liste direkter Abhängigkeiten zusätzliche Zugriffe zur Laufzeit nicht aus.

In diesem Tweak-Binary ist kein `LC_CODE_SIGNATURE`-Befehl vorhanden, obwohl die Framework-Struktur eine `CodeResources`-Datei enthält. Eine gültige iOS-Signatur ist damit nicht nachgewiesen. Für eine Installation müssen App und eingebetteter Code mit einem geeigneten Verfahren signiert werden. Die mitgelieferte Datei ist keine fertig installierbare IPA oder DEB.

Die ursprünglichen Spielzugriffe und eventuellen Freischaltungs-/Serverabhängigkeiten bleiben enthalten. Eine Übertragung auf andere Spielversionen ist ungetestet. Es wurde keine neue Version des Spiels und keine nachgebaute Test-App erstellt.

## Extraktion wiederholen

Python 3 mit Standardbibliothek genügt:

```bash
python3 extract_tweak.py "pool8Signed 2(2).ipa" --out extracted_tweak
```

Das Zielverzeichnis darf noch nicht existieren. Das Werkzeug liest ausschließlich Dateien und führt keinen App- oder Tweak-Code aus. Beim Herauslösen werden die ausgegebenen Framework-Dateien byteweise mit den jeweiligen ZIP-Einträgen verglichen.

## Technische Referenz

Die Bedeutung von `MH_DYLIB`, `LC_LOAD_DYLIB` und `LC_ID_DYLIB` folgt den [Mach-O-Definitionen von Apple](https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/loader.h). Alle konkreten Dateibefunde wurden aus der angehängten IPA ermittelt.

## Beobachtete Klassennamen

- `x2oom1l94npl3`
- `x560m6l35p425o32o804`
- `xl233plo8p2op473lpl81o57`
- `x6lp4m0k54624653p350`
- `xlm33mom80po6n27714`
- `x723k38lo2pnm4343975`
- `x67123860l7`
- `xkm1942o7oo7`
- `x636mkp28750k73499594o58890`
- `xm611381k3ll69o4`
- `xo580n248540630158p2`
- `x31pll3n3`
- `xm5o4mm19959`
- `x1o92m4po94lmnn`
- `x17928no04mo`
- `xmk76993polo17124`
- `xol417o8p8461m304`
- `x0mm8k1m5374mk8l`
- `x6o56534nonm85pl99n2m`
- `xm93ln95796m8p`
- `x857kn4k52574n6`
- `x78po19l3o058k6l1nm0599`
- `x5pp1o23ml6op5`
- `x47non76kkpn08214`
- `xopo0o4280po6nk`
- `x7p34151mmmp88n8no26o`
- `x2197281n9416029026`
- `x0891mln00mm45428613k407045o`
- `x884ppn3o9k988ko5k`
- `x948610lpn1387o7`
- `x90090mn1pp01ll2`
- `x482m0984m7045844l4o65m365214`
- `x77060no4927m6nmo64mk`
- `xn12m7o34m62k6p72nn17lnknll`
