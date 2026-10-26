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

# IntelliJ Google Scripts (`scripts`)

## Overview

Groups runtime user-initialization hooks under `/google/scripts` for the
`intellij` Cloud Workstation layer.

## Subdirectories & Boundaries

- **User Setup Hooks**: [`./user-setup.d/EGM.md`](./user-setup.d/EGM.md) -
  Registers `/opt/ideaIU/bin/remote-dev-server` for JetBrains Gateway
  discovery via `10_register_intellij.sh`.

## Interface

- [`./user-setup.d/EGM.md`](./user-setup.d/EGM.md): `10_register_intellij.sh`
  (`WORKSTATION_USER`).

## Invariants

- Registration only runs when `/opt/ideaIU/bin/remote-dev-server` is
  executable and suppresses non-zero exit codes to preserve boot resilience.

## Side Effects

- Registers the IntelliJ-Ultimate backend location in
  `/home/${WORKSTATION_USER:-user}` via `remote-dev-server
registerBackendLocationForGateway`.
