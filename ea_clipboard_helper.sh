#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Beim Entschlüsseln fordert dieses Helfer-Programm die Passphrase erneut vom Nutzer an.
# Dadurch bleibt die Verschlüsselung robust und der Schlüssel liegt nicht in einem Skript oder
# im Container-Image verborgen vor.
APP_DIR="${HOME}/eAntragExpertenversion"
GPG_FILE="${APP_DIR}/credentials.txt.gpg"
TRACKER_FILE="/dev/shm/ea_clip_state.tmp"

if [[ ! -f "${GPG_FILE}" ]]; then
    zenity --error --title="eAntrag Tresor" --text="Keine GPG-Datei gefunden:
${GPG_FILE}
Bitte die Zugangsdaten zuerst einrichten." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
    zenity --error --title="eAntrag Tresor" --text="GPG ist nicht installiert.
Bitte aktivieren Sie GPG im Container, damit die gespeicherten Daten wieder entschlüsselt werden können." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

PASSPHRASE=$(zenity --password --title="eAntrag Tresor - Entschlüsselung" --text="Bitte geben Sie die Passphrase für die gespeicherten Zugangsdaten ein." 2>/dev/null) || {
    zenity --warning --title="eAntrag Tresor" --text="Entschlüsselung abgebrochen." --width=480 >/dev/null 2>&1 || true
    exit 1
}

if ! DECRYPTED=$(printf '%s' "$PASSPHRASE" | gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 0 --decrypt "$GPG_FILE" 2>/dev/null); then
    zenity --error --title="eAntrag Tresor" --text="Passphrase falsch oder Datei beschädigt.
Bitte erneut versuchen." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

USER_NAME="${DECRYPTED%%:*}"
PASS_WORD="${DECRYPTED#*:}"

if [[ -z "$USER_NAME" || -z "$PASS_WORD" ]]; then
    zenity --error --title="eAntrag Tresor" --text="Die entschlüsselte Datei enthält keine gültigen Zugangsdaten." --width=500 >/dev/null 2>&1 || true
    exit 1
fi

if [[ ! -f "${TRACKER_FILE}" ]]; then
    printf '%s' "$USER_NAME" | xclip -selection clipboard
    printf '%s' "password_next" > "${TRACKER_FILE}"

    zenity --info --title="eAntrag Tresor (Schritt 1)" --text="Benutzername kopiert.
Bitte im eAntrag-Fenster mit Strg+V einfügen.
Die Zwischenablage wird automatisch nach 15 Sekunden gelöscht." --width=480 >/dev/null 2>&1 || true

    (sleep 15 && printf '%s' "" | xclip -selection clipboard >/dev/null 2>&1) &
else
    printf '%s' "$PASS_WORD" | xclip -selection clipboard
    rm -f "${TRACKER_FILE}"

    zenity --info --title="eAntrag Tresor (Schritt 2)" --text="Kennwort kopiert.
Bitte im eAntrag-Fenster mit Strg+V einfügen.
Die Zwischenablage wird automatisch nach 15 Sekunden gelöscht." --width=480 >/dev/null 2>&1 || true

    (sleep 15 && printf '%s' "" | xclip -selection clipboard >/dev/null 2>&1) &
fi
