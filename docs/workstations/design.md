<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# System Architecture & Design: Custom Workstation Images

This document outlines the architectural layers, system technologies, and rendering stability design patterns implemented across the custom Cloud Workstation images.

---

## 1. Modular Layer Overview

The custom workstation image is composed of composable dependency layers:

### 1.1 Preflight Layer (Web Frontend & Gateway)

The Preflight layer is responsible for the initial user experience and traffic control proxying.

- **Technologies**: Vanilla TypeScript, Vite, HTML5, Tailwind CSS, Nginx.
- **Key Features**:
  - **Dynamic Reverse Proxy**: Routes WebSockets and HTTP dynamically to CodeOSS or Guacamole.
  - **Health Polling & Backoff**: The web UI implements exponential backoff to poll the backend readiness, hiding connection errors from users.
  - **Localization (i18n)**: Full support for multiple languages dynamically loaded by the browser.

### 1.2 Base Layer (OS & Tooling Orchestrator)

The Base layer unifies dependency acquisition and runtime OS injection mechanisms.

- **Technologies**: Systemd, Chezmoi, Bash Build Hooks.
- **Key Features**:
  - **Environment Discovery**: Automatically downloads and maps tools (Antigravity CLI, Agent Development Kit, Devcontainers CLI, gVisor) based on environment flags.
  - **Traffic Control**: Employs systemd logic (`permit-traffic.service`) to gate external network access until backend systems report fully healthy.
  
### 1.3 Remote Desktop Layer (Gateway Infrastructure)

Sets up the Apache Guacamole ecosystem explicitly designed for visual OS runtimes.

- **Technologies**: Apache Guacamole, Tomcat, TigerVNC.
- **Key Features**:
  - **Containerized Network Translation**: Bootstraps the backend RDP/VNC translation daemons natively within Systemd context.
  - **Ephemeral Credential Ingestion**: Reads ephemeral `$RDP_PASSWORD` tokens dynamically into `user-mapping.xml`.

### 1.4 GNOME Layer (Graphical Wayland Runtime)

Provides the OS graphical shells and extensions.

- **Technologies**: GNOME Shell (Headless Wayland), Mutter, RDP.
- **Key Features**:
  - **Headless Soft Rendering**: Executes Wayland rendering pipeline natively inside a container runtime environment via standard fallback flags.

### 1.5 CodeOSS Layer (Headless Compute)

Inherits tooling and environment hooks for a pristine headless IDE workspace context, dropping the heavy footprint of Remote Desktop.

---

## 2. Rendering Stability (GPU & Headless)

This section describes the standardized approach for ensuring graphical applications (Electron, Chromium, etc.) run stably in both GPU-enabled and headless (CPU-only) Cloud Workstations environments.

### 2.1 The Challenge

Cloud Workstations can be configured with or without attached GPUs. Applications that rely on hardware acceleration often crash or render incorrectly (e.g., solid gray windows) when running in a headless Wayland session without a GPU, unless specific stability flags are provided.

### 2.2 Centralized GPU Detection

The blueprint provides a centralized environment variable, `WORKSTATION_GPU_ENABLED`, defined in `/google/scripts/common.sh`. This variable is automatically set to `true` or `false` during workstation startup based on the presence of `/dev/dri` or `/dev/nvidia0`.

### 2.3 The "Shadowing Wrapper" Pattern

To support both GPU and non-GPU configurations without modifying original package files, we use the **Shadowing Wrapper** pattern:

1.  **Wrapper Script**: Create a bash script in `/usr/local/bin/` with the same name as the target application (e.g., `google-chrome-stable`).
2.  **Conditional Logic**: The script sources `common.sh` and applies stability flags ONLY if `WORKSTATION_GPU_ENABLED` is `false`.
3.  **PATH Priority**: Since `/usr/local/bin` precedes `/usr/bin` in the system `$PATH`, both terminal users and desktop entries will automatically use the wrapper.

#### Example Wrapper Script

```bash
#!/bin/bash
set -euo pipefail
source /google/scripts/common.sh

FLAGS=("--no-sandbox" "--ozone-platform=wayland")

if [[ "${WORKSTATION_GPU_ENABLED}" == "false" ]]; then
  # Flags for stable software rendering
  FLAGS+=("--disable-gpu" "--in-process-gpu" "--disable-gpu-sandbox")
fi

exec /usr/bin/original-binary "${FLAGS[@]}" "$@"
```

### 2.4 Recommended Stability Flags

For Electron and Chromium-based applications in headless environments, the following flags are recommended:

| Flag                       | Purpose                                                                |
| :------------------------- | :--------------------------------------------------------------------- |
| `--ozone-platform=wayland` | Forces the Wayland backend (required for our GNOME session).           |
| `--disable-gpu`            | Disables hardware acceleration.                                        |
| `--in-process-gpu`         | Runs the GPU thread inside the browser process (prevents IPC crashes). |
| `--disable-gpu-sandbox`    | Disables the GPU sandbox (avoids SIGTRAP/133 errors).                  |
| `--disable-dev-shm-usage`  | Prevents crashes related to `/dev/shm` size limits in containers.      |

### 2.5 Integrating with Desktop Entries

When using a wrapper, ensure the `.desktop` file points to the wrapper (usually just the binary name if it's in `/usr/local/bin`) rather than the absolute path to the original binary in `/usr/bin`.

```ini
[Desktop Entry]
Name=My App
Exec=my-app-name %U
```
