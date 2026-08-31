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

# IntelliJ Ultimate Devcontainer (with Antigravity CLI & SDK)

This standalone DevContainer provides a pre-configured IntelliJ IDEA Ultimate backend environment equipped with the **Antigravity CLI** and **Python SDK**.

## Features

- **Base Image**: `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`
- **Antigravity CLI**: v1.1.22 (`antigravity-cli`, symlinked as `agy`)
- **Antigravity SDK**: v0.1.15 (`/opt/antigravity-sdk` exported via `PYTHONPATH`)
- **SSH Forwarding**: Port `22` is exposed for JetBrains Remote Development and Cloud Workstations plugin connections.

## Usage

### 1. In Cloud Workstations (Code OSS / CLI)

Run inside a Cloud Workstation with Docker enabled:

```bash
devcontainer up --workspace-folder .
```

### 2. Building via CI / Skaffold

```bash
skaffold build -p devcontainer-intellij
```
