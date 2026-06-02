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

# Android Studio for Platform (ASfP) Layer Design Document

## 1. Context and Scope

**Goal**: The Android Studio for Platform (ASfP) Layer provides a specialized, high-performance development environment tailored specifically for AOSP (Android Open Source Project) developers.

**Scope**: This document covers the specific application layer configurations built on top of the GNOME base image.

**Documentation Context**: This layer adheres to the **Thin Layer Philosophy** and **Centralized Configuration** patterns defined in the [GNOME Design Document](../../gnome/docs/design.md). Refer to that document for details on OS lifecycle, Wayland orchestration, and Remote Access.

## 2. Detailed Design: ASfP-Specific Integration

### Multi-Stage Cuttlefish Build

The ASfP layer includes robust support for the Cuttlefish Android emulator.

- **Design Rationale**: Rather than installing pre-built binaries, Cuttlefish is compiled from source in a dedicated build stage (`cuttlefish-builder`). This guarantees exact kernel module compatibility with the underlying Ubuntu base OS used in the Cloud Workstation.
- **Source Patching**: To improve build stability, especially in environments with strict network controls or connectivity issues to kernel.org, a script (`patch_sources.sh`) replaces flaky git kernel URLs with GitHub mirrors during the build phase.

### Hook System & Runtime Configuration

The ASfP layer heavily utilizes the post-install hook system to ensure the toolchain is properly configured:

- `10_install_aosp_tooling.sh`: responsible for installing the custom Cuttlefish `.deb` packages and fixing critical library symlinks (such as `libncurses.so` and `libtinfo.so`) which are often expected by legacy AOSP tooling.
- `20_patch_asfp_desktop.sh`: Patches the IDE's `.desktop` entry to force the native Wayland backend (`GDK_BACKEND=wayland`) and enables it in the JetBrains Runtime (`-Dwayland.enabled=true`). To ensure stability during session startup, the hook points the desktop entry to a wrapper script that utilizes the centralized `/google/scripts/desktop_utils.sh` to wait for both the Wayland socket and an active virtual monitor. This deterministic polling prevents "no screen devices" errors and graphics initialization failures, ensuring the "Android Studio Setup Wizard" and main IDE windows render correctly at full size. It also ensures the `StartupWMClass` is correctly set for dock integration.

### Runtime Initialization (Systemd/Startup)

Hardware-accelerated emulation requires specific system permissions.

- Scripts placed in `/etc/workstation-startup.d/` (e.g., `011_add-cuttlefish-groups.sh`) dynamically add the workstation user to necessary virtualization groups (`kvm`, `cvdnetwork`, `render`) at runtime. This ensures the permissions align correctly when the Cloud Workstation container actually starts.

## 3. Advanced Tooling & Workflows

### AOSP Helper Scripts

The image bundles several built-in scripts located in `/google/scripts/` to standardize complex AOSP workflows:

- `build_aosp.sh`: Streamlines the OS compilation process.
- `start_vcar_cvd.sh` / `stop_vcar_cvd.sh`: Helpers to manage virtual device lifecycles (specifically for Automotive contexts).

### Android Build File System (ABFS)

- **Status**: Experimental Feature (Early Access Program - EAP).
- **Purpose**: ABFS is designed to significantly optimize disk I/O for massive AOSP builds.
- **Opt-in**: This feature is disabled by default. It can be enabled via the `INSTALL_ABFS_CLIENT=true` build argument. Interested users must reach out to their Google Cloud PSO, Technical Account Manager, or account team for access and support regarding ABFS.
