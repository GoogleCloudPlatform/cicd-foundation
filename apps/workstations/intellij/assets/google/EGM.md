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

# IntelliJ Google Assets (`google`)

## Overview

Houses Google-managed runtime user-setup hooks under `/google` for the
`intellij` Cloud Workstation layer.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Registers the
  IntelliJ-Ultimate backend for JetBrains Gateway during `user_setup.sh`
  execution.

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md):
  `user-setup.d/10_register_intellij.sh`.

## Invariants

- User-setup hooks execute after `/home/${WORKSTATION_USER}` ownership is
  initialized by `user_setup.sh`.

## Side Effects

- Executes `remote-dev-server registerBackendLocationForGateway` as
  `${WORKSTATION_USER:-user}`.
