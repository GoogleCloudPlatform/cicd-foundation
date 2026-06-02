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

# AI Agent Instructions: GNOME Desktop Layer

These mandates apply specifically to the GNOME desktop environment.

## 1. Desktop Engineering Standards

- **Systemd Lifecycle**: Ensure all workstation services (Guacamole, GNOME, Docker) are managed via systemd unit files.
- **Extension Compatibility**: utilize local patches for GNOME extensions where necessary.
- **Bash Standards**: utilize the standardized logger in `apps/workstations/preflight/assets/google/scripts/common.sh`.
- **Monitor Detection**: All autostarted graphical applications MUST utilize the `wait_for_monitor` function from `/google/scripts/desktop_utils.sh` to ensure the virtual display is ready before startup.

## 2. Global Foundation Skills

Desktop development utilizes global foundation tools for lifecycle and validation:
👉 **[Foundation Skills](../../../AGENTS.md#3-global-agent-skills-foundation)**

## 3. Mandatory Testing

Verify the environment using the Bats integration suite:

```bash
skills/validate-image-updates/scripts/run_integration_tests.sh
```

---

👉 **[Design Document](docs/design.md)** | 👉 **[Technical Requirements](docs/requirements.md)** | 👉 **[System Overview](../docs/system_overview.md)**
