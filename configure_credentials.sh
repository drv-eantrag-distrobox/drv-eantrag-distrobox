#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Die Zugangsdaten werden hier bewusst im Container als verschlüsselte Datei gespeichert.
# Der Nutzer muss die Passphrase beim Entschlüsseln erneut eingeben; sie bleibt nicht im
# Container-Image oder in der App selbst gespeichert.
APP_DIR="${HOME}/eAntragExpertenversion"
GPG_FILE="${APP_DIR}/credentials.txt.gpg"
TMP_FILE="/dev/shm/ea_credentials.$$"

mkdir -p "${APP_DIR}"

if [[ -f "${GPG_FILE}" ]]; then
    exit 0
fi

if ! command -v gpg >/dev/null 2>&1; then
    zenity --error --title="eAntrag Tresor" --text="GPG ist nicht installiert.
Bitte installieren Sie GPG im Container, damit die Zugangsdaten sicher verschlüsselt werden können." --width=480 >/dev/null 2>&1 || true
    exit 1
fi

EXPLAIN="Das sichere Speichern von Benutzername und Kennwort ist besser als das Aufschreiben auf Papier oder das Ablegen unverschlüsselter Dateien.

Wichtig: Merken Sie sich die Verschlüsselungs-Passphrase. Ohne sie können die Zugangsdaten nicht wiederhergestellt werden.

Hinweis: Das Kennwort muss später im eAntrag-Client selbst gesetzt werden."
zenity --info --title="eAntrag Tresor - Hinweis" --text="$EXPLAIN" --width=560 >/dev/null 2>&1 || true

FORM_OUTPUT=$(zenity --forms     --title="eAntrag Zugang anlegen"     --text="Bitte geben Sie Benutzername und Kennwort ein.
Die Daten werden verschlüsselt gespeichert."     --add-entry="Benutzername"     --add-password="Kennwort"     --separator="::" 2>/dev/null) || {
    zenity --warning --title="eAntrag Tresor" --text="Einrichtung abgebrochen." --width=480 >/dev/null 2>&1 || true
    exit 1
}

USERNAME="${FORM_OUTPUT%%::*}"
PASSWORD="${FORM_OUTPUT#*::}"

PASSPHRASE=$(zenity --password --title="Verschlüsselungs-Passphrase" --text="Geben Sie eine sichere Passphrase ein, mit der die Zugangsdaten verschlüsselt werden." 2>/dev/null) || {
    zenity --warning --title="eAntrag Tresor" --text="Einrichtung abgebrochen: keine Passphrase eingegeben." --width=480 >/dev/null 2>&1 || true
    exit 1
}

PASSPHRASE_CONFIRM=$(zenity --password --title="Passphrase bestätigen" --text="Bestätigen Sie die Passphrase." 2>/dev/null) || {
    zenity --warning --title="eAntrag Tresor" --text="Einrichtung abgebrochen: Bestätigung fehlgeschlagen." --width=480 >/dev/null 2>&1 || true
    exit 1
}

if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
    zenity --error --title="eAntrag Tresor" --text="Die Passphrase stimmt nicht überein. Bitte erneut starten." --width=480 >/dev/null 2>&1 || true
    exit 1
fi

printf '%s:%s' "$USERNAME" "$PASSWORD" > "$TMP_FILE"
chmod 600 "$TMP_FILE"

# GPG wird hier mit einer expliziten Passphrase und dem Loopback-Mode gestartet.
# Damit läuft die Verschlüsselung zuverlässig auch ohne grafischen GPG-Agent im Container.
if ! printf '%s' "$PASSPHRASE" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$GPG_FILE" "$TMP_FILE"; then
    zenity --error --title="eAntrag Tresor" --text="Die Verschlüsselung ist fehlgeschlagen. Bitte erneut versuchen." --width=480 >/dev/null 2>&1 || true
    shred -u "$TMP_FILE" 2>/dev/null || rm -f "$TMP_FILE"
    exit 1
fi

shred -u "$TMP_FILE" 2>/dev/null || rm -f "$TMP_FILE"
zenity --info --title="eAntrag Tresor" --text="Zugangsdaten sicher gespeichert.
Merken Sie sich die Passphrase — ohne diese ist kein Zugriff möglich.

Wichtig: Das Kennwort muss später im eAntrag-Client gesetzt werden." --width=560 >/dev/null 2>&1 || true

exit 0
