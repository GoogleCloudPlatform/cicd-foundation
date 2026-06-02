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

# AI Agent Instructions: Antigravity Layer

Specific mandates for the Antigravity application environment.

## 1. Application Engineering Standards

- **GPU Bypassing**: Always utilize the `/usr/local/bin/antigravity` wrapper to launch the application with `--disable-gpu` to ensure stability in headless environments.
- **Autostart Stability**: The application startup wrapper MUST utilize the centralized `wait_for_monitor` utility from the GNOME layer to ensure graphics environment readiness.
- **UX Integration**: Application registration (favorites, autostart) must be performed via the centralized `desktop_integration.sh` utility in a post-install hook.

## 2. Mandatory Testing

Verify the application and dashboard:

```bash
skills/validate-image-updates/scripts/run_integration_tests.sh
```

---

👉 **[Design Document](docs/design.md)** | 👉 **[Technical Requirements](docs/requirements.md)** | 👉 **[GNOME Foundation](../gnome/AGENTS.md)**
