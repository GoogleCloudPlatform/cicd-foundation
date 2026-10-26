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

# Code-OSS Devcontainer IntelliJ Startup Hooks (`workstation-startup.d`)

## Overview

Workstation startup hook (`050_seed-devcontainer.sh`) that seeds the IntelliJ
devcontainer configuration template from `/opt/devcontainer/intellij` into
`/home/${WORKSTATION_USER:-user}/.devcontainer` on first boot and enables
systemd user lingering so user services start automatically.

## Interface

- `050_seed-devcontainer.sh`: Startup hook script defining
  `seed_devcontainer()` and `main()`.
- `WORKSTATION_USER`: Optional environment variable (defaults to `'user'`).

## Invariants

- Runs under strict mode (`set -euo pipefail`).
- Idempotent seeding: `/home/${WORKSTATION_USER:-user}/.devcontainer` is only
  populated if it does not already exist and `/opt/devcontainer/intellij`
  exists, preserving any existing user `.devcontainer` directory.
- Protected by a sourcing guard (`[[ "${BASH_SOURCE[0]}" == "${0}" ]]`) so
  `main` only executes when invoked directly.
- Systemd user lingering file
  `/var/lib/systemd/linger/${WORKSTATION_USER:-user}` is ensured on every
  invocation.

## Side Effects

- Creates `/home/${WORKSTATION_USER:-user}/.devcontainer` and copies
  `/opt/devcontainer/intellij/*` into it if absent.
- Recursively sets ownership (`chown -R`) of
  `/home/${WORKSTATION_USER:-user}/.devcontainer` to
  `${workstation_user}:${workstation_user}`.
- Creates `/var/lib/systemd/linger` and touches
  `/var/lib/systemd/linger/${workstation_user}` to enable systemd user service
  lingering.
