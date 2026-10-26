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

# Code-OSS Devcontainer IntelliJ Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `codeoss-devcontainer-intellij`
Cloud Workstation layer, containing build-time hooks (`build-hooks.d`), SSH and
systemd configurations and startup hooks (`etc`), and the devcontainer
supervisor script (`google/scripts`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Reconfigures host `sshd` to port `2222`, rewrites
  `/opt/devcontainer/intellij/devcontainer.json` to use
  `devcontainer-intellij:latest`, and preloads
  `/opt/images/intellij-ultimate.tar`.
- **System Configuration & Startup**: [`./etc/EGM.md`](./etc/EGM.md) - Seeds
  `~/.devcontainer` on first boot and enables systemd user lingering via
  `050_seed-devcontainer.sh`.
- **Google Scripts**: [`./google/EGM.md`](./google/EGM.md) - Provides
  `/google/scripts/start_intellij_devcontainer.sh` to load cached container
  images and start the IntelliJ devcontainer.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `02_configure_sshd_port.sh`, `08_configure_devcontainer_template.sh`, and
  `10_preload_devcontainer_image.sh`.
- [`./etc/EGM.md`](./etc/EGM.md): `050_seed-devcontainer.sh`.
- [`./google/EGM.md`](./google/EGM.md): `start_intellij_devcontainer.sh`.

## Invariants

- Host SSH listens on port `2222` so port `22` remains available for the
  IntelliJ devcontainer SSH server.
- Cached image `/opt/images/intellij-ultimate.tar` is loaded and tagged as
  `devcontainer-intellij:latest` before `devcontainer up` runs.

## Side Effects

- Modifies `/etc/ssh/sshd_config`, preloads
  `/opt/images/intellij-ultimate.tar`, seeds `~/.devcontainer`, enables
  systemd user lingering, and launches the IntelliJ devcontainer via
  `devcontainer up`.
