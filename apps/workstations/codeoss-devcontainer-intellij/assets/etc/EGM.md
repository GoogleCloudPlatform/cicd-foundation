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

# Code-OSS Devcontainer IntelliJ System Configuration (`etc`)

## Overview

System configuration files and boot-time hooks under `/etc` for the
`codeoss-devcontainer-intellij` workstation layer, including SSH daemon port
overrides (`ssh/sshd_config.d/20-port.conf`), systemd unit definitions
(`systemd/system`, `systemd/user/intellij-devcontainer.service`), and
devcontainer seeding startup scripts (`workstation-startup.d`).

## Subdirectories & Boundaries

- **Workstation Startup Hooks**:
  [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md) - Seeds
  `/home/${WORKSTATION_USER:-user}/.devcontainer` from
  `/opt/devcontainer/intellij` and enables systemd user lingering via
  `050_seed-devcontainer.sh`.

## Interface

- [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md):
  `050_seed-devcontainer.sh` (`seed_devcontainer`, `main`,
  `WORKSTATION_USER`).

## Invariants

- Preserves existing user `.devcontainer` configurations across workstation
  restarts and ensures systemd user lingering is active for
  `intellij-devcontainer.service`.

## Side Effects

- Populates `/home/${WORKSTATION_USER:-user}/.devcontainer` on first boot,
  sets user ownership, and creates
  `/var/lib/systemd/linger/${WORKSTATION_USER:-user}`.
