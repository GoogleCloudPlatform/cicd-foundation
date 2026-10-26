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

# GNOME Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `gnome` Cloud Workstation layer,
containing GNOME extension and system build hooks (`build-hooks.d`),
dconf/Guacamole/Polkit/systemd configurations and shell profile scripts (`etc`),
Wayland session and RDP/CRD runtime scripts (`google`), and Chrome desktop
post-install hooks (`post-install-hooks.d`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Installs and patches GNOME Shell extensions
  (`01_install_gnome_extensions.sh`), renders Guacamole/desktop systemd
  templates (`03_system_config.sh`), and registers base dock applications
  (`99_setup_desktop.sh`).
- **System Configuration**: [`./etc/EGM.md`](./etc/EGM.md) - Appends
  `/google/bin` to interactive `PATH` (`profile.d/google-bin.sh`) and provides
  systemd, dconf, Polkit, and Guacamole configurations.
- **Google Scripts**: [`./google/EGM.md`](./google/EGM.md) - Provides headless
  Wayland GNOME session orchestration (`start_gnome_session.sh`,
  `gnome_setup.sh`, `desktop_utils.sh`), RDP/CRD setup (`configure_rdp.sh`,
  `chrome_remote_desktop_setup.sh`, `layer_readiness_probe.sh`), and
  `.desktop` integration (`scripts/build/desktop_integration.sh`).
- **Post-Install Hooks**:
  [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md) - Patches
  `google-chrome.desktop` to use `/usr/local/bin/google-chrome-stable`
  (`15_patch_chrome_desktop.sh`).
- **User Binaries** (`./usr/local/bin`): Provides the `google-chrome-stable`
  wrapper script that initializes `gnome-keyring-daemon` and launches
  `/usr/bin/google-chrome-stable` with container and GPU/Wayland stability
  flags.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `01_install_gnome_extensions.sh`, `03_system_config.sh`, and
  `99_setup_desktop.sh`.
- [`./etc/EGM.md`](./etc/EGM.md): `profile.d/google-bin.sh`.
- [`./google/EGM.md`](./google/EGM.md): `desktop_utils.sh`
  (`wait_for_monitor`), `start_gnome_session.sh`, `configure_rdp.sh`,
  `gnome_setup.sh`, `chrome_remote_desktop_setup.sh`,
  `layer_readiness_probe.sh`, and `build/desktop_integration.sh`
  (`desktop_register_app`, `desktop_apply_integration`).
- [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md):
  `15_patch_chrome_desktop.sh`.
- `usr/local/bin/google-chrome-stable`: Google Chrome container stability and
  keyring wrapper.

## Invariants

- Enforces native Wayland session environment variables
  (`GDK_BACKEND=wayland`) with LLVMpipe fallback when
  `WORKSTATION_GPU_ENABLED="false"`, and gates RDP readiness on
  `gnome-remote-desktop` logging `"RDP server started"`.

## Side Effects

- Installs and patches GNOME Shell extensions, compiles GLib/dconf schemas,
  configures headless RDP (`grdctl`) and TLS certificates, manages the Wayland
  GNOME session, and registers dock favorites and XDG autostart entries.
