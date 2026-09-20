# ReconstructedSafeMenu

Rekonstruierte KingMenu-Testoberfläche aus der vorhandenen IPA-/Menüanalyse.

## Zweck

Diese Version rekonstruiert die sichtbare Menüstruktur als eigenständigen UIKit-Code:

- schwebender K-Button
- Prediction
- Tuning
- Automation
- Auto Queue
- Account
- Switches und Slider
- lokale Speicherung über NSUserDefaults

## Wichtig

Diese Version enthält bewusst **keinen alten Schutzmechanismus** und keine zugehörigen Komponenten:

- keine Ed25519-Signaturprüfung
- keine proof-mismatch / proof-revoked Logik
- keine clock-rollback Prüfung
- keinen Lizenzserver
- keine Tamper-Prüfung

Automation-/Queue-Elemente sind reine lokale UI-Testeinstellungen. Es gibt keine Live-Spielsteuerung, keinen Auto-Aim-/Auto-Play-Code und keine Anti-Cheat-Umgehung.

## Dateien

- `Main.m` – rekonstruierte UIKit-Menüoberfläche
- `Info.plist` – Framework-Metadaten
- `build.sh` – baut `KingReconstructed.framework`

## Build

Auf einem Mac mit Xcode:

```bash
cd Tweak/ReconstructedSafeMenu
chmod +x build.sh
./build.sh
```

Danach liegt das Framework unter:

`dist/KingReconstructed.framework`

und als ZIP unter:

`dist/KingReconstructed.framework.zip`
