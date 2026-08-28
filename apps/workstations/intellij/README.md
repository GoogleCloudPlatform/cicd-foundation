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

# IntelliJ Ultimate Workstation Image

This module provides a custom Google Cloud Workstations environment layered on top of the predefined IntelliJ IDEA Ultimate base image (`us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`).

## Features

- **JetBrains Remote Development**: Designed for connection from a local IntelliJ IDEA installation using the Google Cloud Workstations plugin (communicating securely over SSH on port 22).
- **DevContainers CLI**: Installs `@devcontainers/cli` to support devcontainer workflows within the workstation.
- **gVisor Container Isolation**: Installs and configures gVisor (`runsc`) for secure container execution.
- **Preflight Web & Status Service**: Integrates the Nginx preflight static webserver on port 80 to provide live container readiness probes (`/readyz`, `/livez`) and serve informational workstation startup status.
- **Systemd Lifecycle**: Standardized systemd init process with graceful startup hooks and Cloud Logging journal integration.
