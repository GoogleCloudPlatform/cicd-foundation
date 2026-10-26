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

# GNOME Cloud Workstation Layer (`gnome`)

## Overview

Headless graphical desktop layer built on top of `remote-desktop` that provides
a Wayland + Mutter GNOME Shell desktop environment, native GNOME Remote Desktop
(`grdctl` on port `3389`) and Guacamole web streaming, Chrome Remote Desktop
(`CRD`) support, display monitor readiness polling (`wait_for_monitor`), and
declarative `.desktop` dock favorite and XDG autostart integration for
downstream IDE layers.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains GNOME Shell extension installers and CSS patches, systemd
  session/RDP unit configurations, `/google/scripts` session/RDP/readiness
  scripts, and `desktop_integration.sh` for child layers.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): `/google/scripts/desktop_utils.sh`
  (`wait_for_monitor`), `/google/scripts/start_gnome_session.sh`,
  `/google/scripts/configure_rdp.sh`, `/google/scripts/gnome_setup.sh`,
  `/google/scripts/layer_readiness_probe.sh`,
  `/google/scripts/build/desktop_integration.sh` (`desktop_register_app`,
  `desktop_apply_integration`, `WORKSTATION_DEFAULT_APP`), and
  `/usr/local/bin/google-chrome-stable`.

## Invariants

- Runs GNOME Shell headlessly over Wayland (`WAYLAND_DISPLAY=wayland-0`,
  `GDK_BACKEND=wayland`), automatically enabling software rendering
  (`llvmpipe`) when no GPU is attached (`WORKSTATION_GPU_ENABLED=false`).
- Requires downstream autostarted GUI wrappers to call `wait_for_monitor` from
  `/google/scripts/desktop_utils.sh` before launching graphical windows.

## Side Effects

- Installs GNOME Shell, extensions, and Google Chrome during image build,
  compiles GSettings overrides (`99-workstation-favorites.gschema.override`),
  and manages `gnome-session@user.service` and
  `gnome-remote-desktop@user.service` at runtime.
