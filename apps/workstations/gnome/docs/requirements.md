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

# GNOME Layer Technical Requirements

## 1. Functional Requirements

- **FR-G1: Graphical Session**: Must provide a stable, headless Wayland session using GNOME Shell.
- **FR-G2: Remote Access**: Must expose the graphical session via RDP (port 3389) using `gnome-remote-desktop`.
- **FR-G3: Web Gateway**: Must provide a browser-based entrypoint via Apache Guacamole, seamlessly mapping to the internal RDP session.
- **FR-G4: Extension Model**: Must support a build-time and post-install hook system to allow downstream layers to inject custom configurations.

## 2. Non-Functional Requirements

- **NFR-G1: Performance**: The graphical environment must be ready for user connection within **180 seconds** of container start.
- **NFR-G2: Reliability**: Critical desktop services (gnome-session, guacd, tomcat) must achieve a **99.9% initialization success rate**.
- **NFR-G3: Security**: RDP credentials must be generated uniquely per container instance and injected into the GNOME keyring.
- **NFR-G4: Compatibility**: Must enforce software rendering (`LIBGL_ALWAYS_SOFTWARE=1`) to ensure stability on standard, non-GPU machine types.
- **NFR-G5: Graphics Stability**: Must provide a deterministic mechanism for autostarted applications to detect virtual monitor availability, avoiding race conditions during headless session initialization.

## 3. Technical Constraints

- **Orchestration**: All services must be managed via native Systemd units (no persistent bash entrypoint scripts).
- **Startup Sync**: Applications launched via XDG Autostart must wait for both the Wayland socket and at least one initialized logical monitor (provided via Mutter's `DisplayConfig` DBus interface).
- **Inheritance**: Must build upon the `Preflight` base image.
- **Base OS**: Standardized on Ubuntu 24.04 (Noble Numbat).
