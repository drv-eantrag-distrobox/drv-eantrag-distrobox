#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${HOME}/eAntragExpertenversion"
APP_BIN="${APP_DIR}/eAntrag"
CONFIG_DIR="${APP_DIR}/light_config"

# Wichtiger Fix: Java nutzt `xdg-open` über den Prozess-Pfad. Deshalb muss /usr/local/bin
# vor /usr/bin liegen, damit unser Host-Bridge-Wrapper statt des Standard-Launchers greift.
export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"

# Der Container nutzt den Host-Desktop und den Host-CUPS-Server. Deshalb müssen DISPLAY,
# XDG_RUNTIME_DIR und CUPS_SERVER dem Host entsprechend weitergereicht werden.
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-X-Cinnamon}"

if [[ -S "/var/run/cups/cups.sock" ]]; then
    export CUPS_SERVER="/var/run/cups/cups.sock"
fi

mkdir -p "${CONFIG_DIR}"

export GDK_BACKEND=x11
export GTK_THEME=Adwaita:light
export XDG_CONFIG_HOME="${CONFIG_DIR}"

if [[ ! -x "${APP_BIN}" ]]; then
    zenity --error         --title="eAntrag-Umgebung"         --text="Die eAntrag-Datei wurde nicht gefunden.
Bitte prüfen Sie das Verzeichnis ${APP_DIR} oder wählen Sie die ZIP-Datei erneut aus."         --width=500         >/dev/null 2>&1 || true
    exit 1
fi

exec "${APP_BIN}" "$@"
