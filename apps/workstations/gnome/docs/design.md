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

# GNOME Layer Design Document

## 1. Context and Scope

**Primary Goal**: The GNOME layer is responsible for providing a performant, headless graphical environment within the workstation container. It provides the core remote desktop environment and orchestrates the user's graphical session.

**Scope**: This document covers:

- GNOME Shell orchestration and Systemd service management.
- The Remote Desktop Protocol implementation (`gnome-remote-desktop`).
- The containerized Web Gateway (Apache Guacamole).
- The hook-based extension model for downstream layers.

## 2. Architecture Overview & Inheritance

### Thin Layer Philosophy

The GNOME layer establishes a "Thin Layer" architectural pattern for all downstream specialized images (e.g., Android Studio for Platform). Child layers are designed to be lightweight applications on top of this foundation, relying entirely on the parent for:

- Core OS lifecycle and Systemd orchestration.
- The Wayland compositor and RDP remote access protocol.
- Security mechanisms and ephemeral credential management.

### Centralized & Declarative Configuration

To avoid duplicating complex setup logic, the GNOME layer provides a centralized configuration script (`/google/scripts/build/configure_workstation.sh`). All child layers delegate their build-time tasks to this script by:

1.  **Declarative ENVs**: Injecting package lists via `EXTRA_PKGS` and `EXTRA_DEB_URLS`.
2.  **Asset Injection**: Mirroring their `assets/` directory into the image root.
3.  **Hook Execution**: Utilizing the `/build-hooks.d/` and `/post-install-hooks.d/` directories for safe extensions.

This ensures that critical security updates and regional optimizations applied to the base image are automatically inherited by all downstream images.

### Hardware Assumptions

Cloud Workstation instances are expected to run without dedicated GPUs by default. To ensure maximum compatibility and stability across standard GCP machine types, this layer enforces **software rendering** (`LIBGL_ALWAYS_SOFTWARE=1`) and operates the GNOME shell in a dedicated `--headless` mode.

## 3. Detailed Design: Orchestration & Lifecycle

### Native Systemd Lifecycle

To avoid brittle bash-script entrypoints, this layer utilizes a declarative native Systemd pattern (`multi-user.target.d/10-workstation.conf`) to ensure all graphical services are enabled, ordered, and managed robustly.

### The Startup Sequence

The GNOME orchestration is tightly integrated into the broader workstation startup sequence defined by Preflight:

1.  **Rendering Stage**: Systemd triggers `config-rendering.service` (inherited from Preflight), which generates an ephemeral password and renders the Guacamole `user-mapping.xml`.
2.  **User Initialization**: `user-setup.service` configures the unprivileged workstation user's environment. Crucially, it unlocks the GNOME Keyring using the newly generated ephemeral password.
3.  **Graphical Session**: `gnome-session@user.service` starts the headless Wayland shell. This, in turn, triggers the `gnome-remote-desktop-daemon`, which begins listening on the internal RDP port (3389).
4.  **Gateway Handover**: The Preflight UI (serving via Nginx) polls the health endpoint. Once Guacamole is initialized, the browser is redirected to the Guacamole endpoint, establishing the RDP session.

## 4. Detailed Design: Remote Access & Security

### Containerized Guacamole (Docker-in-Docker)

Rather than installing Apache Guacamole directly via APT, it is run as containerized workloads (`guacd` and the Tomcat web application) managed by Systemd via a Docker-in-Docker (DinD) configuration.

- **Design Rationale**: This approach significantly simplifies maintenance, avoids OS dependency hell (specifically regarding Java and Tomcat versioning), and provides a clean upgrade path, which outweighs the overhead of running a nested Docker daemon.

### Ephemeral Security Model

Credentials for the RDP session are highly ephemeral:

- A unique password is generated per container start.
- This password is injected dynamically into Guacamole's `user-mapping.xml`.
- The password is used to seamlessly unlock the GNOME keyring for the session.
- These credentials are never persisted to disk across workstation restarts, heavily locking down unauthorized or stale access.

## 5. Detailed Design: Build-Time Orchestration & Hooks

The GNOME layer introduces a mandatory, opinionated hook system orchestrated by the `configure_workstation.sh` script. Because the GNOME layer is where the base OS (Ubuntu) is significantly mutated with `apt` packages, it serves as the logical integration point for child layers (like Android Studio for Platform) to extend the image cleanly without modifying the core `Dockerfile`.

### Build Phase Sequence

The `configure_workstation.sh` script executes the following steps in a precise order:

1.  **APT Configuration**: Adjusts APT sources for the target region (`GCP_REGION`).
2.  **Build Hooks (`/build-hooks.d/`)**: Executes custom scripts _before_ packages are installed. This is the ideal place to add new APT repositories or inject custom binaries.
3.  **Dependency Resolution**: Refreshes package lists and automatically installs `apt-transport-artifact-registry` if the `ar+` protocol is detected.
4.  **Package Installation**: Installs all packages listed in `EXTRA_PKGS` and downloads/installs all `.deb` files from `EXTRA_DEB_URLS`.
5.  **Post-Install Hooks (`/post-install-hooks.d/`)**: Executes scripts _after_ installation. This is the primary point for patching files provided by third-party packages.
6.  **Desktop Integration**: Calls the `desktop_apply_integration` utility to handle autostart and dock pinning.
7.  **Finalization & Cleanup**: Compiles system-wide overrides (`dconf update`) and removes temporary hook directories to minimize image size.

### Declarative Installation Pattern

Child layers are required to use the `ARG` -> `ENV` mapping pattern in their `Dockerfile` to provide a single source of truth for installed packages.

**Standard Pattern**:

```dockerfile
# 1. Layer-specific ARGs
ARG MY_APP_PKGS="package-a package-b"
# 2. Map to ENVs for the centralized installer
ENV EXTRA_PKGS="${MY_APP_PKGS}"
# 3. Merge assets (including hooks)
COPY assets/ /
# 4. Run centralized configuration
RUN /google/scripts/build/configure_workstation.sh
```

## 6. Detailed Design: Desktop UX Integration

Desktop integration (autostart, dock pinning, menu visibility) is managed automatically through a metadata-driven system located in `/google/scripts/build/desktop_integration.sh`.

### Autodiscovery Logic

- **Autostart**: Applications with `X-GNOME-Autostart-enabled=true` in their `.desktop` file are automatically symlinked into `/etc/xdg/autostart/`.
- **Dock Pinning**: Applications with `Categories=` containing `Development` or `IDE` are automatically pinned to the GNOME favorites dock.

### Manual Application Registration

Downstream layers can explicitly manage application registration using the `desktop_register_app` utility within a build hook.

**Usage**: `desktop_register_app <desktop_file_path> [priority] [autostart] [favorite]`

### Best Practices for Autostart

When configuring applications to autostart, especially those using the native **Wayland backend**, it is mandatory to use a **deterministic polling loop** to avoid race conditions during session initialization. In headless cloud environments, the Wayland socket might exist before GNOME Shell has fully initialized a virtual monitor. Launching a Java/AWT or graphics-intensive application before a monitor is available leads to "no screen devices" errors.

This layer provides a centralized utility script, `/google/scripts/desktop_utils.sh`, which includes a robust `wait_for_monitor()` function that polls Mutter's `DisplayConfig` via DBus.

**Recommended Pattern (Wrapper Script)**:

To ensure stability, move the polling logic into a dedicated wrapper script in `/usr/local/bin/` and source the centralized utilities.

```bash
# Example: /usr/local/bin/my-application-wrapper
#!/bin/bash
# shellcheck source=/dev/null
source /google/scripts/desktop_utils.sh

# Wait for GNOME Shell to initialize at least one monitor
wait_for_monitor

# Explicitly export environment variables for the Wayland backend
export GDK_BACKEND=wayland

exec /opt/my-app/bin/my-app --flags "$@"
```

Then, use a simple `Exec` line in the application's `.desktop` file:

```ini
Exec=/usr/local/bin/my-application-wrapper
```

## 7. CI/CD Orchestration

The image build lifecycle is managed using the `cicd-foundation` Terraform modules.

- **Skaffold Integration**: Build and tag strategies are defined in `skaffold.yaml` for consistency across development and production pipelines.
- **Automated Builds**: Nightly builds are triggered via Cloud Scheduler to ensure "Image Freshness" and automated security patching.
- **Validation**: The agentic 6-step validation lifecycle (as defined in `AGENTS.md`) is required for all changes during development to ensure structural and behavioral integrity.

## 8. Observability and Structured Logging

The workstation image implements a standardized, SLO-agnostic logging strategy to facilitate external monitoring and reporting.

- **Structured Logging**: Critical services log lifecycle events (e.g., `STARTING`, `READY`, `FAILURE`) as structured key-value pairs to the Systemd journal.
- **Decoupled SLOs**: The application is agnostic to specific Service Level Objectives. It provides the "signals" (timestamps, health markers) via logs, while the "SLO definitions" are managed externally in Cloud Monitoring.
- **Health Probes**: Internal health status is emitted as periodic log signals, allowing external systems to calculate availability independently.
- **Reporting Examples**: This project provides Terraform code examples in `examples/terraform` for setting up Cloud Monitoring dashboards and alerting policies that consume these signals.
