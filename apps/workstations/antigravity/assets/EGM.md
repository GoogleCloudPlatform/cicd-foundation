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

# Antigravity Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) copied into the Antigravity Cloud
Workstation container image, containing APT repository configurations
(`etc/apt`), the `/usr/local/bin/antigravity` launch wrapper (`usr/local/bin`),
and post-install desktop integration hooks (`post-install-hooks.d`).

## Subdirectories & Boundaries

- **Post-Install Hooks**:
  [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md) - Rewrites
  `/usr/share/applications/antigravity.desktop` to invoke
  `/usr/local/bin/antigravity` and registers Antigravity for GNOME dock
  pinning and XDG autostart.
- **User Binaries** (`./usr/local/bin`): Provides the `antigravity` wrapper
  script that awaits `wait_for_monitor`, starts `gnome-keyring-daemon`, and
  launches `/usr/share/antigravity/antigravity` with `--no-sandbox` and
  conditional `--disable-gpu` flags.

## Interface

- [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md):
  `10_patch_antigravity_desktop.sh` (`DESKTOP_FILE`).
- `usr/local/bin/antigravity`: Antigravity IDE stability and keyring wrapper.

## Invariants

- Post-install hooks require `/google/scripts/common.sh` and
  `/google/scripts/build/desktop_integration.sh` from parent workstation
  layers.

## Side Effects

- Updates `/usr/share/applications/antigravity.desktop` in-place and registers
  GNOME desktop integration metadata during image build.
