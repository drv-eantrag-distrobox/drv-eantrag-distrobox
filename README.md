# drv-eantrag-distrobox

## Verwendung

1. WSL2 installieren

   - Windows 11: Ubuntu LTS aus dem Microsoft Store installieren
   - oder im PowerShell:

     wsl --install

2. Ubuntu starten und Pakete installieren

   sudo apt update && sudo apt install -y distrobox podman gnupg zenity xclip unzip

3. Distrobox-Container erstellen

   Das fertige Image kommt aus GitHub Container Registry:

   distrobox create --name drv-eantrag --image ghcr.io/drv-eantrag-distrobox/drv-eantrag-distrobox:latest --replace

   Wenn du lokal bauen willst:

   docker build -t drv-eantrag-distrobox:latest .
   distrobox create --name drv-eantrag --image drv-eantrag-distrobox:latest --replace

4. Starten mit dem kurzen Befehl

   distrobox enter drv-eantrag -- start

   Alternativ mit spezifischem Pfad:

   distrobox enter drv-eantrag -- start /opt/eantrag-data

   Oder per Umgebungsvariable:

   EANTRAG_APP_DIR=/opt/eantrag-data distrobox enter drv-eantrag -- start

5. Beim ersten Start

   - Die Installationsdatei auswählen, falls noch nicht vorhanden
   - Typisch: `eAntragExpert_591_linux64_20260610.tar.gz`
   - Hinweis: Der Download muss in der Regel über den vom Träger zur Verfügung gestellten Link aus der E-Mail erfolgen; das Portal-Passwort stammt aus dem blauen Brief.
   - Benutzername und Kennwort eingeben
   - Verschlüsselungspassphrase setzen
   - Die Daten bleiben im normalen Host-Home unter ~/eAntragExpertenversion/, sofern kein anderer Pfad angegeben wurde

Wichtig:

- Die Start- und Hilfsskripte kommen mit dem Image mit.
- Der normale Host-Home wird von Distrobox automatisch gemountet und bleibt der persistente Datenbereich.
- GPG läuft im Container.
- Das Kennwort muss später zusätzlich im eAntrag-Client selbst gesetzt werden.
- Standardstarter ist Dark Mode.
- Unterstützte Installationsformate: `.tar.gz`, `.tgz` und `.zip`.

## Upgrade

Wenn ein neues Image verfügbar ist:

  distrobox create --name drv-eantrag --image ghcr.io/drv-eantrag-distrobox/drv-eantrag-distrobox:latest --replace

Die Daten in ~/eAntragExpertenversion/ bleiben erhalten, weil Distrobox den normalen Host-Home-Ordner weiter nutzt.

## Technische Details

- `start` ist ein Alias auf `/usr/local/bin/start_eantrag_sandbox.sh` via `distrobox.ini`.
- `start_eantrag_sandbox.sh` akzeptiert optional einen alternativen Installationspfad als erstes Argument.
- `EANTRAG_APP_DIR` kann ebenfalls als Umgebungsvariable gesetzt werden.
- `start_eantrag_dark.sh` und `start_eantrag_light.sh` sind im Container mitgeliefert.
- `ea_clipboard_helper.sh` kopiert Benutzername und Kennwort aus dem verschlüsselten Tresor in die Zwischenablage.
- `configure_credentials.sh` ist der GUI-Erstdialog für Benutzername, Kennwort und Passphrase.

## Rechtliches & Haftung

* **Inoffiziell:** Dieses Projekt ist privat und steht in keiner Verbindung zur Deutschen Rentenversicherung (DRV).
* **Keine Software:** Der offizielle eAntrag-Client ist nicht enthalten. Du musst die Installationsdateien selbst bei der DRV herunterladen und in die Box kopieren.
* **Keine Beratung:** Die geplante Abrechnungsfunktion ist keine Rechts- oder Steuerberatung.
* **Eigene Verantwortung:** Nutzung auf eigene Gefahr. Prüfe den Code und das Image selbst, bevor du es nutzt. Es wird keinerlei Haftung für Fehler, Schäden oder falsche Abrechnungen übernommen.
