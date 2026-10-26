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

# Android Studio for Platform Layer (`android-studio-for-platform`)

## Overview

Cloud Workstation container image layer built on top of the `gnome` layer that
provisions Android Studio for Platform (`ASFP` / `ASfP`), AOSP (Android Open
Source Project) build dependencies, Cuttlefish Virtual Device (`CVD`) emulation
packages, optional Android Build File System (`ABFS`) client packages, and
AOSP/AAOS (`VCAR`, Virtual Car / Android Automotive OS) build and emulator
helper scripts.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains build/post-install hooks, runtime startup scripts
  (`workstation-startup.d`), AOSP/AAOS helper scripts (`/google/scripts`), and
  the `/usr/local/bin/asfp-studio` Wayland wrapper.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): Build hooks
  (`05_normalize_permissions.sh`, `30_install_abfs.sh`), post-install hooks
  (`10_install_aosp_tooling.sh`, `20_patch_asfp_desktop.sh`), startup scripts
  (`011_add-cuttlefish-groups.sh`, `200_add-asfp-defaults.sh`), AOSP/CVD
  scripts (`build_aosp.sh`, `build_vcar.sh`, `start_vcar_cvd.sh`,
  `stop_vcar_cvd.sh`, `cleanup_for_snapshot.sh`), and the
  `/usr/local/bin/asfp-studio` launch wrapper.

## Invariants

- Forces native Wayland rendering (`GDK_BACKEND=wayland`,
  `-Dwayland.enabled=true`) via `/usr/local/bin/asfp-studio` and waits for an
  active virtual monitor (`wait_for_monitor`) before launching the IDE.
- Dynamically grants `kvm`, `cvdnetwork`, and `render` group memberships at
  container boot and scales ASfP JVM heap to 70% of RAM (up to 64 GB).

## Side Effects

- Fetches and installs Cuttlefish `.deb` packages and ASfP IDE binaries during
  image build, configures AOSP library symlinks and desktop entries, and
  manages AOSP checkouts and Cuttlefish emulator instances at runtime.
