# syntax=docker/dockerfile:1.7
# =====================================================================
# LAUFZEITUMGEBUNG FÜR DRV EANTRAG & PAUSCHALEN-ABRECHNUNG
# =====================================================================
# Letzter erfolgreicher CI-Test: 2026-08-19 (Ubuntu 22.04 LTS / Java 21)
# Bei Major-Updates (z.B. Java 25) einfach die ARG-Werte beim Build anpassen.
ARG JAVA_VERSION=21
ARG UBUNTU_CODENAME=noble  # Ubuntu 24.04 LTS "Noble Numbat"
ARG EANTRAG_VERSION=dev

FROM docker.io/library/eclipse-temurin:${JAVA_VERSION}-jre-${UBUNTU_CODENAME}

# Quelle des Images (OCI-Label) — zeigt auf das Quell-Repository
LABEL org.opencontainers.image.source="https://github.com/drv-eantrag-distrobox/drv-eantrag-distrobox"

ENV DEBIAN_FRONTEND=noninteractive     LANG=C.UTF-8     LC_ALL=C.UTF-8     HOME=/home/distrobox     PATH=/usr/local/bin:${PATH}

# Minimal notwendige GUI-/Druck-/Clipboard-Abhängigkeiten für die Container-Laufzeit.
# Wichtig: Der Container soll keine eigenen Drucker-Queues konfigurieren. Er nutzt die Host-CUPS-
# Infrastruktur und den Host-Desktop über X11/Wayland. Deshalb reichen Client-Tools und PDF-/GUI-
# Helfer aus; die eigentliche Druck- und Desktop-Integration bleibt auf dem Host.
RUN apt-get update     && apt-get install -y --no-install-recommends        ca-certificates        cups        cups-client        cups-filters        cups-pdf        dbus-x11        evince        ghostscript        gnupg        inotify-tools        libasound2        libcups2        libgtk-3-0        libx11-6        libxext6        libxi6        libxrender1        libxtst6        xauth        xclip        unzip        xdg-utils        zenity     && apt-get clean     && rm -rf /var/lib/apt/lists/*

# Die eigentlichen Start- und Hilfsskripte kommen mit dem Image mit. Der Host-Home wird von
# Distrobox automatisch gemountet und ist der persistente Datenbereich. So bleiben die Skripte
# einfach im Container, aber die echten Nutzerdaten bleiben im normalen Home-Verzeichnis.
COPY start_eantrag_sandbox.sh /usr/local/bin/start_eantrag_sandbox.sh
COPY start_eantrag_dark.sh /usr/local/bin/start_eantrag_dark.sh
COPY start_eantrag_light.sh /usr/local/bin/start_eantrag_light.sh
COPY ea_clipboard_helper.sh /usr/local/bin/ea_clipboard_helper.sh
COPY configure_credentials.sh /usr/local/bin/configure_credentials.sh
COPY setup_virtual_pdf_printer.sh /usr/local/bin/setup_virtual_pdf_printer.sh
COPY watch_print_dropzone.sh /usr/local/bin/watch_print_dropzone.sh
COPY open_pdf_from_container.sh /usr/local/bin/open_pdf_from_container.sh
COPY start_eantrag_host_pdf.sh /usr/local/bin/start_eantrag_host_pdf.sh
COPY start /usr/local/bin/start

RUN chmod 0755 /usr/local/bin/start /usr/local/bin/start_eantrag_sandbox.sh     /usr/local/bin/start_eantrag_dark.sh     /usr/local/bin/start_eantrag_light.sh     /usr/local/bin/ea_clipboard_helper.sh     /usr/local/bin/configure_credentials.sh     /usr/local/bin/setup_virtual_pdf_printer.sh     /usr/local/bin/watch_print_dropzone.sh     /usr/local/bin/open_pdf_from_container.sh     /usr/local/bin/start_eantrag_host_pdf.sh     && mkdir -p /home/distrobox/eAntragExpertenversion     && mkdir -p /home/distrobox/.local/bin     && chown -R 1000:1000 /home/distrobox

# Wenn ein Git-Tag gesetzt ist, wird die Version in die Laufzeit-Datei geschrieben.
RUN if [ -n "${EANTRAG_VERSION}" ] && [ "${EANTRAG_VERSION}" != "dev" ]; then \
    printf '%s\\n' "${EANTRAG_VERSION}" > /etc/eantrag_version; \
  else \
    printf '%s\\n' "dev" > /etc/eantrag_version; \
  fi

# Smoke-Test beim Build: Java muss die konfigurierte LTS-Version ausführen.
RUN java -version
