# SYSTEM INSTRUCTIONS FOR GITHUB COPILOT

## High-Level Objective
Create a secure, long-term maintainable, and high-performance containerized runtime environment (Podman + Distrobox) for the German DRV eAntrag software. The host is WSL2 (Ubuntu) or native Linux. 
The configuration must support multi-year upgrades (e.g., switching from Java 21 to future Java 25 LTS) via central variables without breaking the environment.

## Target Audience: Senior Insurance Advisors (Nicht-IT-Experten)
* **User Experience:** Zero-terminal, 1-click execution for the user.
* **UI/UX:** All notifications, errors, and initial setup dialogs must be rendered using `zenity` (in German language) from inside the container onto the host desktop.
* **Data Safety:** Never store or modify personal user files, certificates, or configurations inside the ephemeral container. Everything resides safely in the mapped host home directory (`~/$USER/`).

## Architecture Requirements

### 1. Dynamic Containerfile
* **Base Image:** Use Eclipse Temurin JRE on Ubuntu LTS as base. Use `ARG` variables for Java version and Ubuntu codename to ensure easy future upgrades.
* **Capabilities:** Install minimal dependencies for Audio, Clipboard (`xclip`), ZIP unpacking (`unzip`), X11/Wayland GUI forwarding, and `zenity`.
* **Printing:** Install CUPS client packages (`cups-client`, `libcups2`) to allow the eAntrag application to use the host's printers and generate PDF printouts seamlessly.

### 2. Declarative Distrobox Manifest (`distrobox.ini`)
* **State Management:** Use `replace=true` to update system libraries seamlessly without manual user intervention.
* **Portability:** Use dynamic host mapping via `\$USER` (no hardcoded usernames like `jakob-dev`).
* **Exports:** Automatically export the following three binaries to `~/.local/bin` using `init_hooks`:
  * `/home/\$USER/eAntragExpertenversion/ea_clipboard_helper.sh`
  * `/home/\$USER/eAntragExpertenversion/start_eantrag_dark.sh` (This must be the default starter)
  * `/home/\$USER/eAntragExpertenversion/start_eantrag_light.sh`

### 3. CI/CD Pipeline & Automated Smoke Test (`.github/workflows/`)
* **Hosting:** Private GitHub Repository using GitHub Container Registry (`ghcr.io`).
* **Triggers:** Run weekly on Sundays (for OS security updates) and on git push/tags.
* **Headless Smoke Test:** Run a pre-flight test (`java -version`) inside the pipeline before pushing. Fail the build if the active Java version does not match the configured target `ARG`.
* **Automatic Versioning:** If triggered by a Git Tag (e.g., `v5.9`), automatically extract this string and bake it into a metadata text file at `/etc/eantrag_version` inside the image.

### 4. Robust Host Start Script (`start_eantrag_sandbox.sh`)
* **Initialization:** Read the baked `/etc/eantrag_version` from the container image. Greet the user with a German Zenity info window (e.g., "eAntrag-Umgebung Version 5.9 erfolgreich geladen").
* **Execution Logic:** Launch the environment. By default, it must execute the **Dark Mode** script (`start_eantrag_dark.sh`).
* **First-Time Setup:** If the folder `/home/\$USER/eAntragExpertenversion/` or the scripts are missing, interrupt the launch. Open a German `zenity --file-selection` window, ask the user for their eAntrag ZIP file, and unpack it to the target directory automatically.

## Output Instructions for Copilot
Generate the project files based on these specifications. Ensure clean code, strict error handling for the Zenity file selector, and add **German comments** inside the generated scripts to explain the maintenance workflow to the user.
