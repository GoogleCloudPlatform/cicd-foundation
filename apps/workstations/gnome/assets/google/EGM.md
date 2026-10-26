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

# GNOME Google Assets (`google`)

## Overview

Houses Google-managed runtime session orchestration scripts, RDP/CRD setup
utilities, readiness probes, and build-time desktop integration scripts under
`/google` for the `gnome` Cloud Workstation layer.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides Wayland GNOME
  session management (`start_gnome_session.sh`, `gnome_setup.sh`,
  `desktop_utils.sh`), RDP/CRD configuration (`configure_rdp.sh`,
  `chrome_remote_desktop_setup.sh`, `layer_readiness_probe.sh`), and
  build-time `.desktop` favorite/autostart registration
  (`./scripts/build/desktop_integration.sh`).

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): `desktop_utils.sh`
  (`wait_for_monitor`), `start_gnome_session.sh`, `configure_rdp.sh`,
  `gnome_setup.sh`, `chrome_remote_desktop_setup.sh`,
  `layer_readiness_probe.sh`, and `build/desktop_integration.sh`.

## Invariants

- Enforces native Wayland session variables (`GDK_BACKEND=wayland`), requires
  ephemeral credentials (`EPHEMERAL_PASS`) before enabling headless RDP, and
  gates readiness on `gnome-remote-desktop` logging `"RDP server started"`.

## Side Effects

- Launches the headless GNOME Wayland session and session D-Bus, generates RDP
  TLS certificates, configures `grdctl`, initializes unlocked user keyrings,
  and compiles GSettings dock favorite overrides.
