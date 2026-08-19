#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${HOME}/eAntragExpertenversion"
APP_BIN="${APP_DIR}/eAntrag"
CONFIG_DIR="${APP_DIR}/dark_config"

mkdir -p "${CONFIG_DIR}"

export GDK_BACKEND=x11
export GTK_THEME=Adwaita:dark
export XDG_CONFIG_HOME="${CONFIG_DIR}"

if [[ ! -x "${APP_BIN}" ]]; then
    zenity --error         --title="eAntrag-Umgebung"         --text="Die eAntrag-Datei wurde nicht gefunden.
Bitte prüfen Sie das Verzeichnis ${APP_DIR} oder wählen Sie die ZIP-Datei erneut aus."         --width=500         >/dev/null 2>&1 || true
    exit 1
fi

exec "${APP_BIN}" -clean -clearPersistedState "$@"
