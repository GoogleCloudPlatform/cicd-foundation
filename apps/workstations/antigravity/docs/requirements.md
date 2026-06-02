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

# Antigravity Layer Technical Requirements

## 1. Functional Requirements

- **FR-A1: Dashboard Autostart**: The Antigravity dashboard must launch automatically upon successful RDP connection. This requires deterministic detection of virtual monitor availability to prevent graphics crashes in headless environments.
- **FR-A2: UX Integration**: The application must be pinned to the GNOME dock as a high-priority favorite.
- **FR-A3: Dev-Ready Tooling**: Must include the Agent Development Kit (ADK) and Gemini CLI by default.

## 2. Non-Functional Requirements

- **NFR-A1: Stability**: Must bypass hardware acceleration in the headless environment to prevent Electron-based rendering crashes.

## 3. Technical Constraints

- **Base Foundation**: Must adhere to all requirements defined in the [GNOME Technical Requirements](../../gnome/docs/requirements.md).
- **Packaging**: Must utilize the centralized `configure_workstation.sh` script for all package installations.
