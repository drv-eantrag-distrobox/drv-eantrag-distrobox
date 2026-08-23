#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Dieses Skript öffnet ein generiertes PDF mit dem Standard-Viewer des Hosts.
# Dadurch läuft der eigentliche Druck-Workflow im Container, aber die Anzeige bleibt auf
# der natives Host-Desktop-Umgebung (WSL2/Windows oder Linux).
open_pdf_from_container() {
    local pdf_path="${1:-}"

    if [[ -z "${pdf_path}" ]]; then
        echo "Kein PDF-Pfad angegeben." >&2
        return 1
    fi

    if [[ "${pdf_path}" == file:* ]]; then
        pdf_path="${pdf_path#file:}"
        if [[ "${pdf_path}" == //* ]]; then
            pdf_path="/${pdf_path#//}"
        fi
    fi

    if [[ ! -f "${pdf_path}" ]]; then
        echo "PDF-Datei nicht gefunden: ${pdf_path}" >&2
        return 1
    fi

    # Beste Lösung: Host-Viewer direkt ansprechen, damit kein manuelles Kopieren nötig ist.
    if command -v distrobox-host-exec >/dev/null 2>&1; then
        if distrobox-host-exec command -v wslview >/dev/null 2>&1; then
            distrobox-host-exec wslview "${pdf_path}"
            return 0
        fi

        if distrobox-host-exec command -v xdg-open >/dev/null 2>&1; then
            distrobox-host-exec xdg-open "${pdf_path}"
            return 0
        fi
    fi

    # Wenn kein Host-Exec verfügbar ist, in der aktuellen Umgebung versuchen.
    if command -v wslview >/dev/null 2>&1; then
        wslview "${pdf_path}"
        return 0
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${pdf_path}" >/dev/null 2>&1 &
        return 0
    fi

    if command -v gio >/dev/null 2>&1; then
        gio open "${pdf_path}" >/dev/null 2>&1 &
        return 0
    fi

    if command -v evince >/dev/null 2>&1; then
        evince "${pdf_path}" >/dev/null 2>&1 &
        return 0
    fi

    echo "Kein PDF-Viewer im Host oder Container verfügbar: ${pdf_path}" >&2
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    open_pdf_from_container "$@"
fi
