#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Diese Minimal-Variante erstellt nur den Drucker-Kontext, den Java für javax.print
# benötigt. Sie ist bewusst schlank: kein komplettes Desktop-Printer-Setup, kein cups-pdf,
# keine großen Zusatzpakete. Der Host-Viewer bleibt separat und läuft über den Wrapper in
# /usr/local/bin/xdg-open.

APP_DIR="${EANTRAG_APP_DIR:-${HOME}/eAntragExpertenversion}"
DROPZONE="${APP_DIR}/print_dropzone"
PRINTER_NAME="${PRINTER_NAME:-Auto_PDF_Printer}"
IPP_PORT="${IPP_PORT:-8631}"

mkdir -p "${DROPZONE}"

if ! command -v cupsd >/dev/null 2>&1; then
    echo "CUPS ist nicht installiert." >&2
    exit 1
fi

if ! pgrep -x cupsd >/dev/null 2>&1; then
    /usr/sbin/cupsd
    sleep 2
fi

if pgrep -f "ippeveprinter.*${PRINTER_NAME}" >/dev/null 2>&1; then
    pkill -f "ippeveprinter.*${PRINTER_NAME}" || true
    sleep 1
fi

if command -v ippeveprinter >/dev/null 2>&1; then
    ippeveprinter -d "${DROPZONE}" -p "${IPP_PORT}" "${PRINTER_NAME}" >/tmp/ippeveprinter.log 2>&1 &
else
    echo "ippeveprinter nicht gefunden. Paket: cups-ipp-utils" >&2
    exit 1
fi

for _ in $(seq 1 30); do
    if timeout 2 bash -c "</dev/tcp/127.0.0.1/${IPP_PORT}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! timeout 2 bash -c "</dev/tcp/127.0.0.1/${IPP_PORT}" >/dev/null 2>&1; then
    echo "IPP-Server konnte nicht gestartet werden. Port ${IPP_PORT} bleibt unerreichbar." >&2
    exit 1
fi

if ! lpstat -p "${PRINTER_NAME}" >/dev/null 2>&1; then
    lpadmin -p "${PRINTER_NAME}" -E -v "ipp://localhost:${IPP_PORT}/ipp/print" -m everywhere || {
        echo "Fehler beim Anlegen des Druckers ${PRINTER_NAME}." >&2
        exit 1
    }
fi

lpadmin -d "${PRINTER_NAME}" >/dev/null 2>&1 || true
export PRINTER="${PRINTER_NAME}"
export LPDEST="${PRINTER_NAME}"

exit 0
