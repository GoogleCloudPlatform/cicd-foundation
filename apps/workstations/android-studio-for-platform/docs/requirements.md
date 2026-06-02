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

# Android Studio for Platform (ASfP) Technical Requirements

## 1. Functional Requirements

- **FR-S1: Emulator Support**: Must provide a pre-compiled, kernel-compatible version of the Cuttlefish emulator.
- **FR-S2: Toolchain Parity**: Must include standard AOSP build tools (`repo`, `bison`, `flex`) and fix legacy library symlinks.
- **FR-S3: IDE Visibility**: The "Android Studio Setup Wizard" and main IDE windows must render at full size during autostart. This requires deterministic wait logic for both the Wayland socket and initialized virtual monitors to prevent graphics failures.
- **FR-S4: Virtualization Permissions**: Must dynamically add the workstation user to `kvm` and `cvdnetwork` groups at runtime.

## 2. Non-Functional Requirements

- **NFR-S1: Disk Performance**: Must support the experimental Android Build File System (ABFS) for optimized AOSP build I/O.

## 3. Technical Constraints

- **Base Foundation**: Must adhere to all requirements defined in the [GNOME Technical Requirements](../../gnome/docs/requirements.md).
- **Runtime**: Utilizes the native Wayland backend (`GDK_BACKEND=wayland`) and JBR Wayland support for stable window framing.
