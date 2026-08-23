# drv-eantrag-distrobox

## Verwendung

1. WSL2 / Ubuntu vorbereiten

   - Windows 11: Ubuntu LTS aus dem Microsoft Store installieren oder `wsl --install` ausführen.
   - Auf Linux/WSL2 nur die minimale Host-Vorbereitung nötig:

    ```bash
    sudo apt update
    sudo apt install -y distrobox
    ```

   - Wenn dein System ein Podman-Backend verwendet, installiere zusätzlich das passende Backend (z. B. `podman`).
   - Die restlichen Laufzeitpakete wie GPG, GUI-Tools, CUPS-Client und PDF-Viewer laufen in der Container-Image-Umgebung und müssen nicht auf dem Host installiert werden.

2. Distrobox-Container erstellen

   Das fertige Image kommt aus GitHub Container Registry:

   ```bash
   distrobox create --name drv-eantrag --image ghcr.io/drv-eantrag-distrobox/drv-eantrag-distrobox:latest --replace
   ```

   Wenn du die aktuelle Distrobox-Manifest-Datei direkt aus dem Repository laden willst, kannst du sie auch mit `curl` herunterladen:

   ```bash
   curl -fsSL https://codeberg.org/drv-eantrag-distrobox/drv-eantrag-distrobox/raw/branch/main/distrobox.ini -o distrobox.ini
   ```

   Danach kannst du das Manifest lokal verwenden oder mit einem eigenen Distrobox-Setup weiter anpassen.

   Wenn du lokal bauen willst:

   ```bash
   docker build -t drv-eantrag-distrobox:latest .
   distrobox create --name drv-eantrag --image drv-eantrag-distrobox:latest --replace
   ```

3. Starten

   ```bash
   distrobox enter drv-eantrag -- start
   ```

   Alternativ mit spezifischem Pfad:

   ```bash
   distrobox enter drv-eantrag -- start /opt/eantrag-data
   ```

   Oder per Umgebungsvariable:

   ```bash
   EANTRAG_APP_DIR=/opt/eantrag-data distrobox enter drv-eantrag -- start
   ```

   Optional Theme-Override:

   ```bash
   EANTRAG_THEME=light distrobox enter drv-eantrag -- start
   EANTRAG_THEME=dark distrobox enter drv-eantrag -- start
   ```

4. Beim ersten Start

   - Die Installationsdatei auswählen, falls noch nicht vorhanden.
   - Typisch: `eAntragExpert_591_linux64_20260610.tar.gz`
   - Hinweis: Der Download muss in der Regel über den vom Träger bereitgestellten Link aus der E-Mail erfolgen; das Portal-Passwort stammt aus dem blauen Brief.
   - Benutzername und Kennwort eingeben.
   - Verschlüsselungspassphrase setzen.
   - Die Daten bleiben im normalen Host-Home unter `~/eAntragExpertenversion/`, sofern kein anderer Pfad angegeben wurde.

Wichtig:

- Die Start- und Hilfsskripte kommen mit dem Image mit.
- Der normale Host-Home wird von Distrobox automatisch gemountet und bleibt der persistente Datenbereich.
- GPG, GUI-Tools und PDF-/Druck-Helfer laufen im Container.
- Das Kennwort muss später zusätzlich im eAntrag-Client selbst gesetzt werden.
- Standardstarter ist Dark Mode; Light Mode kann über `EANTRAG_THEME=light` oder `start_eantrag_light.sh` aktiviert werden.
- Unterstützte Installationsformate: `.tar.gz`, `.tgz` und `.zip`.
- Der PDF-Viewer-Fallback nutzt den Host-Desktop; für WSL2/Windows wird dabei normalerweise `wslview` verwendet, für natives Linux `xdg-open`.
- Die Container-Umgebung nutzt hostseitig sichtbaren X11-/CUPS-Kontext; deshalb bleiben Druck-/Viewer-Aktivitäten im Host-Kontext und werden nicht innerhalb der Box als „lokaler Desktop“ simuliert.

## Upgrade

Wenn ein neues Image verfügbar ist:

```bash
distrobox create --name drv-eantrag --image ghcr.io/drv-eantrag-distrobox/drv-eantrag-distrobox:latest --replace
```

Die Daten in `~/eAntragExpertenversion/` bleiben erhalten, weil Distrobox den normalen Host-Home-Ordner weiter nutzt.

## Technische Details

- `start` ist ein Alias auf `/usr/local/bin/start_eantrag_sandbox.sh` via `distrobox.ini`.
- `start_eantrag_sandbox.sh` akzeptiert optional einen alternativen Installationspfad als erstes Argument.
- `EANTRAG_APP_DIR` kann ebenfalls als Umgebungsvariable gesetzt werden.
- `start_eantrag_dark.sh` und `start_eantrag_light.sh` sind im Container mitgeliefert.
- `open_pdf_from_container.sh` versucht, PDFs mit dem Host-Viewer zu öffnen (`wslview` unter WSL2, `xdg-open` auf Linux).
- `ea_clipboard_helper.sh` kopiert Benutzername und Kennwort aus dem verschlüsselten Tresor in die Zwischenablage.
- `configure_credentials.sh` ist der GUI-Erstdialog für Benutzername, Kennwort und Passphrase.
- Der PDF-Drucker-Sandbox ist bewusst optional und nur als Zusatzfunktion verfügbar; die primäre und stabilere Lösung ist Host-aware PDF-Öffnung.

## Rechtliches & Haftung

* **Inoffiziell:** Dieses Projekt ist privat und steht in keiner Verbindung zur Deutschen Rentenversicherung (DRV).
* **Keine Software:** Der offizielle eAntrag-Client ist nicht enthalten. Du musst die Installationsdateien selbst bei der DRV herunterladen und in die Box kopieren.
* **Keine Beratung:** Die geplante Abrechnungsfunktion ist keine Rechts- oder Steuerberatung.
* **Eigene Verantwortung:** Nutzung auf eigene Gefahr. Prüfe den Code und das Image selbst, bevor du es nutzt. Es wird keinerlei Haftung für Fehler, Schäden oder falsche Abrechnungen übernommen.

