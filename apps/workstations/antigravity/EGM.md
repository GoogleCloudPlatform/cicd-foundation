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

# Antigravity Cloud Workstation Layer (`antigravity`)

## Overview

Cloud Workstation container image layer that extends the GNOME desktop image
with the Antigravity IDE installed via APT, a GPU/Wayland stability wrapper
(`/usr/local/bin/antigravity`), and post-install desktop integration hooks.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Provides APT repository configurations, the `/usr/local/bin/antigravity`
  wrapper, and post-install hooks that wire `antigravity.desktop` into GNOME
  dock favorites and XDG autostart.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): Filesystem overlay,
  `/usr/local/bin/antigravity` stability wrapper, and
  `10_patch_antigravity_desktop.sh` post-install hook.

## Invariants

- Inherits `/google/scripts/common.sh` and
  `/google/scripts/build/desktop_integration.sh` from the `common` and `gnome`
  base workstation layers.

## Side Effects

- Installs the Antigravity IDE package during container build, patches
  `/usr/share/applications/antigravity.desktop` to use
  `/usr/local/bin/antigravity`, and enables GNOME dock pinning and session
  autostart.
