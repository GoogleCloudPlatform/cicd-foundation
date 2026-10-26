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

# devcontainers

## Overview

Collection of Development Container (`devcontainer.json`) and Skaffold project
configurations for building and testing isolated development environments and
sample workloads inside Cloud Workstations.

## Subdirectories & Boundaries

- `gvisor-antigravity`:
  [`./gvisor-antigravity/EGM.md`](./gvisor-antigravity/EGM.md) -
  gVisor-isolated (`runsc`) Python 3.12 Development Container pre-installed
  with the Antigravity CLI and Python SDK.
- `intellij`: [`./intellij/EGM.md`](./intellij/EGM.md) - IntelliJ IDEA
  Ultimate remote Development Container pre-installed with the Antigravity CLI
  and Python SDK.
- `node-demo`: [`./node-demo/EGM.md`](./node-demo/EGM.md) - TypeScript and
  Express Node.js Development Container demo application
  (`devcontainer-node-demo`).

## Interface

- [`./gvisor-antigravity/EGM.md`](./gvisor-antigravity/EGM.md): Skaffold
  config `devcontainer-gvisor-antigravity` and gVisor DevContainer definition.
- [`./intellij/EGM.md`](./intellij/EGM.md): Skaffold config
  `devcontainer-intellij` and IntelliJ Ultimate SSH DevContainer definition.
- [`./node-demo/EGM.md`](./node-demo/EGM.md): Skaffold config
  `devcontainer-node-demo` and Express demo application.

## Invariants

- Each subdirectory encapsulates an independent Skaffold (`skaffold.yaml`) and
  Development Container (`.devcontainer/devcontainer.json`) configuration.
- Antigravity CLI and SDK downloads in container builds enforce SHA-256
  checksum verification (`sha256sum -c -`).

## Side Effects

- Building child projects via Skaffold builds container images (using Docker
  or `build_devcontainer`) and pushes artifacts to the configured container
  registry.
