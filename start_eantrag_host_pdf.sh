#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Dieses Skript startet die eAntrag-Umgebung in einer Host-aware PDF-Workflow-Variante.
# Das primäre Design ist: Generiere das PDF im Container, öffne es aber mit dem Host-Viewer
# (WSL2: Windows-Viewer; Linux: xdg-open).
APP_DIR="${1:-${EANTRAG_APP_DIR:-${HOME}/eAntragExpertenversion}}"
APP_BIN="${APP_DIR}/eAntrag"

mkdir -p "${APP_DIR}"

if [[ ! -f "${APP_BIN}" ]]; then
    echo "eAntrag-Binary nicht gefunden: ${APP_BIN}" >&2
    exit 1
fi

export EANTRAG_PDF_OUTPUT="${APP_DIR}/eAntrag_Ausgabe.pdf"

if [[ -f "${APP_DIR}/open_pdf_from_container.sh" ]]; then
    bash "${APP_DIR}/open_pdf_from_container.sh" --help >/dev/null 2>&1 || true
fi

exec "${APP_BIN}" "$@"
