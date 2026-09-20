# Untersuchung: `pool8Signed 2(3).ipa`

## Ergebnis

Die neu hochgeladene Datei `pool8Signed 2(3).ipa` ist **bytegenau identisch** mit der zuvor untersuchten `pool8Signed 2(2).ipa`.

- Dateigröße: `91787405` Bytes
- SHA-256 der gesamten IPA: `3fc6595c83a6c79fcaf3dbcce388fc8b97c3f9a00575607c6711517ff2ec7a54`
- ZIP-Einträge: `3298`
- Unterschiedliche ZIP-Einträge gegenüber `pool8Signed 2(2).ipa`: `0`
- Fehlende oder zusätzliche ZIP-Einträge: `0`

## App

- Bundle-ID: `com.miniclip.8ballpoolmult`
- Version: `56.29.2`
- Build: `5324`
- Hauptprogramm: `Payload/pool.app/pool`
- SHA-256 Hauptprogramm: `58cf8b98a85daf5b96e3bd7e36398181f5bd025553d6aea64729eee02e4515ce`

Damit ist auch das Hauptprogramm exakt das bereits als i3rby-Quellvariante analysierte Programm.

## i3rby / libloader

Pfad:

`Payload/pool.app/Frameworks/libloader.framework/libloader`

- SHA-256: `d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb`
- Mach-O-Typ: `MH_DYLIB`
- Installationsname: `@rpath/libloader.framework/libloader`
- Framework Bundle-ID: `com.appdome.libloader`
- Framework-Version: `1.0.0`
- Minimum iOS: `11.0`

Der Loader enthält weiterhin die bereits bekannten i3rby-Marker, darunter:

- `GBModMenu`
- `GBPredictionDrawView`
- `com.i3rby.8poolmod`
- `Prediction Lines`
- `Pocket Rings`
- `Scratch Alert`
- `Stream Proof`
- `Auto Select Pocket`
- `Aim Mode`
- `Humanization`
- `Break Mode`

## Ladepfad im Hauptprogramm

Das Hauptprogramm enthält genau den bekannten Ladebefehl:

`@executable_path/Frameworks/libloader.framework/libloader`

Es gibt in dieser Quell-IPA kein `iGameGod.framework` und kein zusätzliches `i3rby.framework`.

## Schlussfolgerung

`pool8Signed 2(3).ipa` bringt gegenüber `pool8Signed 2(2).ipa` **keine neue technische Variante**. Für weitere Tests kann sie als exakt dieselbe i3rby-Quelle behandelt werden. Ein erneutes Extrahieren des Tweaks würde wieder exakt dieselbe `libloader`-Datei mit SHA-256 `d44ed5b80ff3418d0ac07829833b95a060da9cf89a0d3d6d9fd2094d70b6dbeb` ergeben.
