#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Dieser Wrapper kann entweder den Standardpfad verwenden oder einen alternativen Pfad
# direkt als Argument akzeptieren:
#   ./start_eantrag_sandbox.sh
#   ./start_eantrag_sandbox.sh /opt/eantrag-data
#   EANTRAG_APP_DIR=/opt/eantrag-data ./start_eantrag_sandbox.sh

APP_DIR="${1:-${EANTRAG_APP_DIR:-${HOME}/eAntragExpertenversion}}"
APP_BIN="${APP_DIR}/eAntrag"
VERSION_FILE="/etc/eantrag_version"
VERSION="unbekannt"
SCRIPT_DIR="/usr/local/bin"

# Wichtig: Die Anwendung läuft im Container, nutzt aber den Host-Desktop und Host-CUPS.
# Dadurch sieht Java den echten CUPS-Server und die echte GUI-Session des Hosts.
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-X-Cinnamon}"

if [[ -S "/var/run/cups/cups.sock" ]]; then
    export CUPS_SERVER="/var/run/cups/cups.sock"
fi

mkdir -p "${APP_DIR}"

for script in start_eantrag_dark.sh start_eantrag_light.sh ea_clipboard_helper.sh configure_credentials.sh setup_virtual_pdf_printer.sh setup_ippeve_pdf_printer.sh watch_print_dropzone.sh open_pdf_from_container.sh; do
    if [[ ! -f "${APP_DIR}/${script}" ]] && [[ -f "${SCRIPT_DIR}/${script}" ]]; then
        install -m 0755 "${SCRIPT_DIR}/${script}" "${APP_DIR}/${script}"
    fi
done

if [[ -f "${VERSION_FILE}" ]]; then
    VERSION="$(tr -d '
' < "${VERSION_FILE}")"
fi

mkdir -p "${APP_DIR}/print_dropzone"

# Die PDF-Sandbox ist jetzt ein stabiler Fallback für den Fall, dass Java nach einem validen
# PrintService verlangt. Sie läuft standardmäßig ohne manuelle Umgebungs-Variable, damit
# der eAntrag-Client nicht mehr wegen eines nullen Druckers abstürzt.
if [[ -x "${APP_DIR}/setup_ippeve_pdf_printer.sh" ]]; then
    "${APP_DIR}/setup_ippeve_pdf_printer.sh" || {
        if command -v zenity >/dev/null 2>&1; then
            zenity --warning --title="eAntrag-Umgebung" --text="Der IPP-Everywhere-PDF-Drucker konnte nicht eingerichtet werden. Die Anwendung startet trotzdem; der Host-Viewer-Fallback bleibt aktiv." --width=520 >/dev/null 2>&1 || true
        fi
    }
fi

if [[ -x "${APP_DIR}/watch_print_dropzone.sh" ]] && ! pgrep -f "watch_print_dropzone.sh" >/dev/null 2>&1; then
    nohup "${APP_DIR}/watch_print_dropzone.sh" >/tmp/eantrag_print_watch.log 2>&1 &
fi

if command -v zenity >/dev/null 2>&1; then
    zenity --info         --title="eAntrag-Umgebung"         --text="eAntrag-Umgebung Version ${VERSION} erfolgreich geladen.
Die Anwendung wird nun gestartet."         --width=500         >/dev/null 2>&1 || true
fi

if [[ ! -d "${APP_DIR}" ]] || [[ ! -f "${APP_BIN}" ]]; then
    if command -v zenity >/dev/null 2>&1; then
        zenity --error             --title="eAntrag-Umgebung"             --text="Die eAntrag-Installation fehlt oder ist unvollständig.
Bitte wählen Sie jetzt die Installationsdatei des eAntrag-Clients aus.
Hinweis: Der Download muss in der Regel über den vom Träger bereitgestellten Link aus der E-Mail und das Portal-Passwort aus dem blauen Brief erfolgen."             --width=600             >/dev/null 2>&1 || true
    fi

    ZIP_FILE="$(zenity --file-selection --title="eAntrag-Installationsdatei auswählen" --file-filter="Archivdateien | *.tar.gz *.tgz *.zip" 2>/dev/null)" || {
        zenity --warning --title="eAntrag-Umgebung" --text="Der Start wurde abgebrochen, da keine Installationsdatei ausgewählt wurde." --width=500 >/dev/null 2>&1 || true
        exit 1
    }

    if [[ -z "${ZIP_FILE}" ]]; then
        zenity --warning --title="eAntrag-Umgebung" --text="Die Auswahl war leer. Der Start wurde abgebrochen." --width=500 >/dev/null 2>&1 || true
        exit 1
    fi

    case "${ZIP_FILE}" in
        *.tar.gz|*.tgz)
            tar -xzf "${ZIP_FILE}" -C "${APP_DIR}" >/dev/null 2>&1 || {
                zenity --error --title="eAntrag-Umgebung" --text="Die TAR.GZ-Datei konnte nicht entpackt werden.
Bitte prüfen Sie die Datei und versuchen Sie es erneut." --width=500 >/dev/null 2>&1 || true
                exit 1
            }
            ;;
        *.zip)
            unzip -o "${ZIP_FILE}" -d "${APP_DIR}" >/dev/null 2>&1 || {
                zenity --error --title="eAntrag-Umgebung" --text="Die ZIP-Datei konnte nicht entpackt werden.
Bitte prüfen Sie die Datei und versuchen Sie es erneut." --width=500 >/dev/null 2>&1 || true
                exit 1
            }
            ;;
        *)
            zenity --error --title="eAntrag-Umgebung" --text="Das ist keine unterstützte Installationsdatei.
Erlaubt sind .tar.gz, .tgz oder .zip." --width=500 >/dev/null 2>&1 || true
            exit 1
            ;;
esac

    if [[ ! -f "${APP_DIR}/credentials.txt.gpg" ]]; then
        "${APP_DIR}/configure_credentials.sh" || {
            zenity --warning --title="eAntrag-Umgebung" --text="Die Anlage der Zugangsdaten wurde nicht abgeschlossen. Sie können dies später über das Hilfsprogramm nachholen." --width=520 >/dev/null 2>&1 || true
        }
    fi
fi

if [[ ! -f "${APP_DIR}/start_eantrag_dark.sh" ]] || [[ ! -f "${APP_DIR}/start_eantrag_light.sh" ]]; then
    zenity --error --title="eAntrag-Umgebung" --text="Ein oder mehrere Starter wurden nicht gefunden. Bitte die Installation prüfen." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

# Theme-Logik:
# - Standard bleibt Dark Mode für eine stabile und konsistente erste Erfahrung.
# - Falls der Host ein helles Theme sauber meldet und der Nutzer dies explizit gewählt hat,
#   kann Light Mode aktiv werden.
# - Wenn keine sichere Erkennung möglich ist, bleibt Dark Mode der sichere Default.
THEME="${EANTRAG_THEME:-dark}"

if [[ "${THEME}" != "light" && "${THEME}" != "dark" ]]; then
    THEME="dark"
fi

if [[ "${THEME}" == "auto" ]]; then
    THEME="dark"
    if command -v gsettings >/dev/null 2>&1; then
        if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -qi 'dark'; then
            THEME="dark"
        else
            THEME="light"
        fi
    fi
fi

if [[ "${THEME}" == "light" ]]; then
    exec "${APP_DIR}/start_eantrag_light.sh" "$@"
fi

exec "${APP_DIR}/start_eantrag_dark.sh" "$@"
