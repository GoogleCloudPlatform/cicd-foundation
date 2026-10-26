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

# IntelliJ Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `intellij` Cloud Workstation layer,
containing build hooks to clean up conflicting legacy startup scripts
(`build-hooks.d`), systemd service overrides (`etc/systemd/system`), and
user-setup hooks to register the IntelliJ Ultimate remote development backend
(`google/scripts/user-setup.d`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Deletes legacy
  `/etc/workstation-startup.d/{020_start-sshd.sh,110_start-intellij-ultimate.sh,130_jetbrains-ready-server.sh}`
  scripts via `01_cleanup_legacy_startup.sh`.
- **Google Assets**: [`./google/EGM.md`](./google/EGM.md) - Registers
  `/opt/ideaIU/bin/remote-dev-server` for JetBrains Gateway via
  `scripts/user-setup.d/10_register_intellij.sh`.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `01_cleanup_legacy_startup.sh`.
- [`./google/EGM.md`](./google/EGM.md):
  `scripts/user-setup.d/10_register_intellij.sh` (`WORKSTATION_USER`).

## Invariants

- Removes legacy startup scripts during build so ports `80` and `22` are
  exclusively managed by systemd (`nginx.service` and `ssh.service`).

## Side Effects

- Deletes legacy startup scripts at build time and executes `remote-dev-server
registerBackendLocationForGateway` as `${WORKSTATION_USER:-user}` during
  user initialization.
