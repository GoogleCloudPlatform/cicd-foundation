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

# AI Agent Instructions: IntelliJ Devcontainer in Code OSS Layer

These mandates apply specifically to the IntelliJ Devcontainer in Code OSS workstation layer.

## 1. Application Engineering Standards

- **Host SSH Port Separation**: The host SSH daemon must strictly bind to port `2222` to ensure port `22` remains unbound on the host network namespace for devcontainer port mapping.
- **Devcontainer Base Image**: The devcontainer MUST build upon `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`.
- **Devcontainer Port Forwarding**: The devcontainer configuration in `devcontainer.json` MUST specify `"forwardPorts": [22]` to expose the IntelliJ remote development SSH server to external Cloud Workstation connections.
- **Antigravity CLI & SDK**: The devcontainer image must package the Antigravity CLI (with symlink `/usr/local/bin/agy`) and SDK in `/opt/antigravity-sdk` with `PYTHONPATH` exported.
- **Workspace Seeding**: The devcontainer template MUST be available in `/opt/devcontainer/intellij/` and seeded into `/home/user/.devcontainer/` on workstation initialization.

## 2. Global Foundation Skills

Workstation development utilizes global foundation tools for lifecycle and validation:
👉 **[Foundation Skills](../../../AGENTS.md#5-global-agent-skills-foundation)**

## 3. Mandatory Testing

Verify the layer using the local test suite:

```bash
skills/validate-image-updates/scripts/run_local_tests.sh
```

---

👉 **[Code OSS Base Layer](../codeoss/README.md)** | 👉 **[IntelliJ Base Layer](../intellij/README.md)**
