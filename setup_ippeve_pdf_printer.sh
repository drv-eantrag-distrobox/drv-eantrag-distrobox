#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Diese Variante nutzt einen echten IPP-Everywhere-Drucker als PDF-Sandbox.
# Java erwartet in der Praxis einen gültigen PrintService; das ist stabiler als ein
# proprietäres cups-pdf-Backend, das in minimalen Container-Umgebungen oft nicht sauber
# initialisiert wird. Die Ausgabe wird in die App-Dropzone geschrieben und danach mit dem
# Host-Viewer geöffnet.
APP_DIR="${EANTRAG_APP_DIR:-${HOME}/eAntragExpertenversion}"
PRINTER_NAME="${PRINTER_NAME:-Auto_PDF_Printer}"
DROPZONE="${APP_DIR}/print_dropzone"
IPP_PORT="${IPP_PORT:-8631}"

mkdir -p "${DROPZONE}"

if ! command -v ippeveprinter >/dev/null 2>&1; then
    echo "ippeveprinter ist nicht installiert." >&2
    exit 1
fi

if ! command -v cupsd >/dev/null 2>&1; then
    echo "CUPS ist nicht installiert." >&2
    exit 1
fi

if ! pgrep -x cupsd >/dev/null 2>&1; then
    /usr/sbin/cupsd
    sleep 2
fi

# Alte Instanzen der gleichen Queue bzw. des gleichen IPP-Servers sauber beenden.
if pgrep -f "ippeveprinter.*${PRINTER_NAME}" >/dev/null 2>&1; then
    pkill -f "ippeveprinter.*${PRINTER_NAME}" || true
    sleep 1
fi

# IPP-Server starten. Der Ausgabeordner bleibt im Host-Home-Kontext des Distrobox-Users;
# dadurch ist der PDF-Ausgabepfad für Java und Host-Viewer konsistent und stabil.
# Wichtig: `-p` legt den tatsächlichen Listening-Port fest; ohne sie versucht CUPS/Java oft,
# den falschen Endpoint zu erreichen, obwohl der Server noch gar nicht gestartet ist.
# In der hier verwendeten CUPS-Version gibt es kein --no-shared-Flag. Deshalb muss Avahi/D-Bus
# aktiviert werden, damit die lokale mDNS-/Bonjour-Initialisierung sauber läuft.
if command -v avahi-daemon >/dev/null 2>&1; then
    mkdir -p /run/dbus
    if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
        dbus-daemon --system --fork >/dev/null 2>&1 || true
    fi
    if ! pgrep -x avahi-daemon >/dev/null 2>&1; then
        avahi-daemon -D >/dev/null 2>&1 || true
    fi
fi

ippeveprinter -v -d "${DROPZONE}" -p "${IPP_PORT}" "${PRINTER_NAME}" >/tmp/ippeveprinter.log 2>&1 &
IPP_PID=$!

for _ in $(seq 1 30); do
    if timeout 2 bash -c "</dev/tcp/127.0.0.1/${IPP_PORT}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Verifizierter Health-Check: Erst jetzt darf der Queue-Eintrag in CUPS geschaffen werden.
if ! timeout 2 bash -c "</dev/tcp/127.0.0.1/${IPP_PORT}" >/dev/null 2>&1; then
    echo "IPP-PDF-Drucker konnte nicht gestartet werden; Port ${IPP_PORT} bleibt unerreichbar." >&2
    kill "${IPP_PID}" 2>/dev/null || true
    exit 0
fi

# Wenn die Queue noch nicht existiert, wird sie explizit per CUPS-API angelegt.
if ! lpstat -p "${PRINTER_NAME}" >/dev/null 2>&1; then
    lpadmin -p "${PRINTER_NAME}" -E -v "ipp://localhost:${IPP_PORT}/ipp/print" -m everywhere || {
        echo "Fehler beim Anlegen des IPP-PDF-Druckers." >&2
        kill "${IPP_PID}" 2>/dev/null || true
        exit 0
    }
fi

lpadmin -d "${PRINTER_NAME}" >/dev/null 2>&1 || true
export PRINTER="${PRINTER_NAME}"
export LPDEST="${PRINTER_NAME}"

exit 0
