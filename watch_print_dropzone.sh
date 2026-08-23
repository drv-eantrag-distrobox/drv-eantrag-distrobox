#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Dieser Watcher überwacht die PDF-Dropzone. Jede neue PDF-Datei wird mit Zeitstempel
# versehen und anschließend mit dem Host-Viewer geöffnet. So bleiben Druck und Anzeige
# vollständig im Desktop-Kontext des Hosts, obwohl der Druck im Container erzeugt wird.
DROPZONE="${HOME}/eAntragExpertenversion/print_dropzone"
OPENER="${HOME}/eAntragExpertenversion/open_pdf_from_container.sh"

mkdir -p "${DROPZONE}"

if [[ ! -f "${OPENER}" ]]; then
    echo "open_pdf_from_container.sh nicht gefunden: ${OPENER}" >&2
    exit 1
fi

if ! command -v inotifywait >/dev/null 2>&1; then
    echo "inotifywait ist nicht installiert." >&2
    exit 1
fi

while true; do
    inotifywait -m -e close_write -e moved_to --format '%f' "${DROPZONE}" 2>/dev/null | while IFS= read -r file_name; do
        case "${file_name}" in
            *.pdf|*.PDF)
                src="${DROPZONE}/${file_name}"
                if [[ ! -f "${src}" ]]; then
                    continue
                fi

                stamp="$(date +%Y%m%d%H%M%S)"
                target="${DROPZONE}/${stamp}_$(basename "${file_name%.pdf}").pdf"
                mv -f "${src}" "${target}"
                bash "${OPENER}" "${target}" || true
                ;;
        esac
    done || break
done
