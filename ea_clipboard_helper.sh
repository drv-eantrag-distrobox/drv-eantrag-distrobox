#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${HOME}/eAntragExpertenversion"
GPG_FILE="${APP_DIR}/credentials.txt.gpg"
TRACKER_FILE="/dev/shm/ea_clip_state.tmp"

if [[ ! -f "${GPG_FILE}" ]]; then
    zenity --error         --title="eAntrag Tresor"         --text="Keine GPG-Datei gefunden:
${GPG_FILE}
Bitte die Zugangsdaten zuerst einrichten."         --width=500         >/dev/null 2>&1 || true
    exit 1
fi

DECRYPTED=""
if ! DECRYPTED=$(gpg --decrypt --batch --no-tty --quiet "${GPG_FILE}" 2>/dev/null); then
    DECRYPTED=$(gpg --decrypt --quiet "${GPG_FILE}" 2>/dev/null || true)
fi

if [[ -z "${DECRYPTED}" ]]; then
    zenity --error         --title="eAntrag Tresor"         --text="YubiKey- oder GPG-Freigabe abgebrochen.
Bitte die Freigabe erneut starten."         --width=500         >/dev/null 2>&1 || true
    exit 1
fi

USER_NAME="${DECRYPTED%%:*}"
PASS_WORD="${DECRYPTED#*:}"

if [[ ! -f "${TRACKER_FILE}" ]]; then
    printf '%s' "${USER_NAME}" | xclip -selection clipboard
    printf '%s' "password_next" > "${TRACKER_FILE}"

    zenity --info         --title="eAntrag Tresor (Schritt 1)"         --text="Benutzername kopiert.
Bitte im eAntrag-Fenster mit Strg+V einfügen.
Die Zwischenablage wird automatisch nach 15 Sekunden gelöscht."         --width=480         >/dev/null 2>&1 || true

    (sleep 15 && printf '%s' "" | xclip -selection clipboard >/dev/null 2>&1) &
else
    printf '%s' "${PASS_WORD}" | xclip -selection clipboard
    rm -f "${TRACKER_FILE}"

    zenity --info         --title="eAntrag Tresor (Schritt 2)"         --text="Kennwort kopiert.
Bitte im eAntrag-Fenster mit Strg+V einfügen.
Die Zwischenablage wird automatisch nach 15 Sekunden gelöscht."         --width=480         >/dev/null 2>&1 || true

    (sleep 15 && printf '%s' "" | xclip -selection clipboard >/dev/null 2>&1) &
fi
