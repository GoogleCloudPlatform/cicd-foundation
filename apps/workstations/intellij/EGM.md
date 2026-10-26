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

# IntelliJ Ultimate Cloud Workstation Layer (`intellij`)

## Overview

Cloud Workstation container image layer that rebases the predefined
`intellij-ultimate` image onto the `preflight` + `common` systemd foundation,
serving the Preflight dashboard on port `80` while registering the
`/opt/ideaIU/bin/remote-dev-server` backend for JetBrains Gateway connections
over SSH (port `22`).

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Removes legacy JetBrains startup scripts (`01_cleanup_legacy_startup.sh`)
  and registers the IntelliJ Ultimate remote development backend during user
  initialization (`10_register_intellij.sh`).

## Interface

- [`./assets/EGM.md`](./assets/EGM.md):
  `build-hooks.d/01_cleanup_legacy_startup.sh` and
  `google/scripts/user-setup.d/10_register_intellij.sh`.

## Invariants

- Prevents legacy `130_jetbrains-ready-server.sh` and `020_start-sshd.sh` from
  binding ports `80` and `22` outside systemd control.

## Side Effects

- Cleans up legacy startup hooks during build and registers
  `/opt/ideaIU/bin/remote-dev-server` in `/home/${WORKSTATION_USER:-user}` at
  runtime.
