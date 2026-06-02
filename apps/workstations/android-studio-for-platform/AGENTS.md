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

# AI Agent Instructions: ASfP Layer

Specific mandates for the Android Studio for Platform (ASfP) environment.

## 1. Application Engineering Standards

- **Wayland Backend**: The IDE must be forced to use the native Wayland backend (`GDK_BACKEND=wayland`) with the JetBrains Runtime flag (`-Dwayland.enabled=true`).
- **Autostart Stability**: The IDE startup wrapper MUST utilize the centralized `wait_for_monitor` utility from the GNOME layer to ensure graphics environment readiness.
- **AOSP Tooling**: When adding or updating AOSP tools, ensure legacy library symlinks are maintained in `10_install_aosp_tooling.sh`.
- **Permissions**: Virtualization groups (`kvm`, `cvdnetwork`) must be managed via startup hooks in `/etc/workstation-startup.d/`.

## 2. Mandatory Testing

Verify the IDE and emulator environment:

```bash
skills/validate-image-updates/scripts/run_integration_tests.sh
```

---

👉 **[Design Document](docs/design.md)** | 👉 **[Technical Requirements](docs/requirements.md)** | 👉 **[GNOME Foundation](../gnome/AGENTS.md)**
