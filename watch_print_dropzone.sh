#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Der Watcher überwacht sowohl die explizite PDF-Dropzone als auch das App-Verzeichnis.
# Dadurch bleiben beide Pfade als Fallback nutzbar: Druckausgaben können in die Dropzone landen,
# aber PDF-Dateien aus dem Standard-Installationsordner werden ebenfalls erkannt und mit dem
# Host-Viewer geöffnet. So bleibt die Lösung stabil, auch wenn eine Java- oder Client-Version
# den Ausgabeort anders wählt.
APP_DIR="${EANTRAG_APP_DIR:-${HOME}/eAntragExpertenversion}"
DROPZONE="${APP_DIR}/print_dropzone"
OPENER="${APP_DIR}/open_pdf_from_container.sh"
WATCH_DIRS=("${DROPZONE}" "${APP_DIR}")

mkdir -p "${DROPZONE}"

if [[ ! -f "${OPENER}" ]]; then
    echo "open_pdf_from_container.sh nicht gefunden: ${OPENER}" >&2
    exit 1
fi

if ! command -v inotifywait >/dev/null 2>&1; then
    echo "inotifywait ist nicht installiert." >&2
    exit 1
fi

handle_pdf() {
    local src="${1:-}"
    if [[ -z "${src}" || ! -f "${src}" ]]; then
        return 0
    fi

    local dir base stamp target
    dir="$(dirname "${src}")"
    base="$(basename "${src}")"

    if [[ "${dir}" == "${DROPZONE}" ]]; then
        stamp="$(date +%Y%m%d%H%M%S)"
        target="${DROPZONE}/${stamp}_${base}"
        mv -f "${src}" "${target}"
        src="${target}"
    fi

    bash "${OPENER}" "${src}" || true
}

while true; do
    inotifywait -m -e close_write -e moved_to --format '%w%f' "${WATCH_DIRS[@]}" 2>/dev/null | while IFS= read -r full_path; do
        case "${full_path}" in
            *.pdf|*.PDF)
                handle_pdf "${full_path}"
                ;;
        esac
    done || break
done
