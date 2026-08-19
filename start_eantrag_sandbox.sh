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

mkdir -p "${APP_DIR}"

for script in start_eantrag_dark.sh start_eantrag_light.sh ea_clipboard_helper.sh configure_credentials.sh; do
    if [[ ! -f "${APP_DIR}/${script}" ]] && [[ -f "${SCRIPT_DIR}/${script}" ]]; then
        install -m 0755 "${SCRIPT_DIR}/${script}" "${APP_DIR}/${script}"
    fi
done

if [[ -f "${VERSION_FILE}" ]]; then
    VERSION="$(tr -d '
' < "${VERSION_FILE}")"
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

if [[ ! -f "${APP_DIR}/start_eantrag_dark.sh" ]]; then
    zenity --error --title="eAntrag-Umgebung" --text="Der Standardstarter wurde nicht gefunden. Bitte die Installation prüfen." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

exec "${APP_DIR}/start_eantrag_dark.sh" "$@"
