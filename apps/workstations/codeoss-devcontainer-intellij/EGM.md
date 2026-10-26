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

# Code-OSS Devcontainer IntelliJ Layer (`codeoss-devcontainer-intellij`)

## Overview

Cloud Workstation container image layer built on `codeoss` that runs both
Code-OSS on the host (port `8080`, host SSH on port `2222`) and a pre-cached
IntelliJ Ultimate devcontainer listening on SSH port `22` for JetBrains Gateway
connections.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains build hooks (`02_configure_sshd_port.sh`,
  `08_configure_devcontainer_template.sh`,
  `10_preload_devcontainer_image.sh`), boot-time seeding hooks
  (`050_seed-devcontainer.sh`), and the `start_intellij_devcontainer.sh`
  runtime supervisor.
- **DevContainer Template** (`./.devcontainer`): Contains
  `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json`, copied to
  `/opt/devcontainer/intellij/` during image build (`Dockerfile:29`) and used
  to pre-build `/opt/images/intellij-ultimate.tar` and seed
  `/home/user/.devcontainer`.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): Build hooks, startup hooks, and
  `/google/scripts/start_intellij_devcontainer.sh`.
- `.devcontainer/Dockerfile` & `.devcontainer/devcontainer.json`: IntelliJ
  Ultimate DevContainer image and container specification.

## Invariants

- Moves host `sshd` to port `2222` to reserve port `22` for the IntelliJ
  devcontainer.
- Preloads `intellij-ultimate.tar` into `/opt/images` during image build so
  runtime startup does not require external image pulls.

## Side Effects

- Configures dual-SSH ports (`2222` host, `22` devcontainer), seeds
  `/home/user/.devcontainer`, loads `/opt/images/intellij-ultimate.tar` into
  Docker, and starts the IntelliJ devcontainer via systemd user service
  `intellij-devcontainer.service`.
