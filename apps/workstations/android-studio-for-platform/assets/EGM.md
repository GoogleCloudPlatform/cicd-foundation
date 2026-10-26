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

# ASfP Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) copied into the Android Studio for Platform
(`ASFP` / `ASfP`) Cloud Workstation image, containing pre-install build hooks
(`build-hooks.d`), system configuration and runtime startup scripts (`etc`),
AOSP/AAOS workflow scripts (`google`), post-install hooks
(`post-install-hooks.d`), and the `/usr/local/bin/asfp-studio` Wayland wrapper
(`usr/local/bin`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Normalizes `/etc/dconf/profile` permissions and conditionally retains
  `/etc/apt/sources.list.d/abfs.list` based on `INSTALL_ABFS_CLIENT`.
- **System Configuration & Startup**: [`./etc/EGM.md`](./etc/EGM.md) -
  Configures `kvm`, `cvdnetwork`, and `render` group permissions and tunes
  ASfP `studio64.vmoptions` JVM heap and IntelliSense settings at boot.
- **Google Scripts**: [`./google/EGM.md`](./google/EGM.md) - Provides
  `/google/scripts` utilities for AOSP and AAOS (`VCAR`) builds, Cuttlefish
  Virtual Device (`CVD`) lifecycle management, and pre-snapshot credential
  cleanup.
- **Post-Install Hooks**:
  [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md) - Installs
  Cuttlefish `.deb` packages and `libncurses5`/`libtinfo5` symlinks, and
  patches `asfp-canary.desktop` to invoke `/usr/local/bin/asfp-studio`.
- **User Binaries** (`./usr/local/bin`): Provides the `asfp-studio` Wayland
  wrapper script that waits for an active GNOME monitor (`wait_for_monitor`)
  and launches `/opt/asfp/android-studio-for-platform-canary/bin/studio.sh`
  with `GDK_BACKEND=wayland` and `-Dwayland.enabled=true`.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `05_normalize_permissions.sh` and `30_install_abfs.sh`
  (`INSTALL_ABFS_CLIENT`).
- [`./etc/EGM.md`](./etc/EGM.md): `011_add-cuttlefish-groups.sh` and
  `200_add-asfp-defaults.sh`.
- [`./google/EGM.md`](./google/EGM.md): `build_aosp.sh`, `build_vcar.sh`,
  `start_vcar_cvd.sh`, `stop_vcar_cvd.sh`, and `cleanup_for_snapshot.sh`.
- [`./post-install-hooks.d/EGM.md`](./post-install-hooks.d/EGM.md):
  `10_install_aosp_tooling.sh` and `20_patch_asfp_desktop.sh`.
- `usr/local/bin/asfp-studio`: Wayland IDE launcher wrapper.

## Invariants

- Build hooks execute prior to APT package installation, post-install hooks
  require `/cuttlefish` `.deb` artifacts, and runtime startup hooks cap ASfP
  JVM heap at 64 GB (`64000m`).

## Side Effects

- Installs Cuttlefish packages and legacy library symlinks, patches
  `asfp-canary.desktop` and `studio64.vmoptions`, assigns virtualization
  groups (`kvm`, `cvdnetwork`, `render`) to `user`, and provides AOSP/CVD
  runtime scripts under `/google/scripts`.
