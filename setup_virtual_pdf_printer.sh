#!/usr/bin/env bash
set -Eeuo pipefail

# Pflegehinweis:
# Dieser Dienst richtet einen virtuellen PDF-Drucker im Container ein. Der Java-Client kann
# damit ohne Drucker-Auswahl einfach drucken; das erzeugte PDF landet in der Dropzone und
# wird danach hostseitig angezeigt.
PRINTER_NAME="Virtual_PDF_Printer"
DROPZONE="${HOME}/eAntragExpertenversion/print_dropzone"

mkdir -p "${DROPZONE}"

if ! command -v cupsd >/dev/null 2>&1; then
    echo "CUPS-Server nicht installiert." >&2
    exit 1
fi

if ! pgrep -x cupsd >/dev/null 2>&1; then
    /usr/sbin/cupsd
    sleep 2
fi

if [[ -f "/etc/cups/cups-pdf.conf" ]]; then
    sed -i "s#^Out .*#Out ${DROPZONE}#" /etc/cups/cups-pdf.conf 2>/dev/null || true
fi

if [[ ! -f "/etc/cups/cups-pdf.conf" ]]; then
    cat > /etc/cups/cups-pdf.conf <<EOF
Log /var/log/cups-pdf.log
Out ${DROPZONE}
AnonData no
DeleteOnSend no
LogLevel 1
EOF
    chmod 0644 /etc/cups/cups-pdf.conf
fi

if ! lpstat -p "${PRINTER_NAME}" >/dev/null 2>&1; then
    if [[ -f "/usr/share/cups/model/CUPS-PDF.ppd" ]]; then
        lpadmin -p "${PRINTER_NAME}" -E -v cups-pdf:/ -m /usr/share/cups/model/CUPS-PDF.ppd
    else
        lpadmin -p "${PRINTER_NAME}" -E -v cups-pdf:/ -m raw
    fi
fi

lpadmin -d "${PRINTER_NAME}" >/dev/null 2>&1 || true

# Wichtig: Der Container nutzt den virtuellen Drucker als Standard-Queue, aber die Anzeige
# des erzeugten PDF läuft weiterhin über den Host-Viewer.
exit 0
