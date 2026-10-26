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

# IntelliJ User Setup Hooks (`user-setup.d`)

## Overview

Contains a user-setup hook script (`10_register_intellij.sh`) executed during
workstation user initialization to register the pre-installed IntelliJ-Ultimate
remote development backend (`/opt/ideaIU/bin/remote-dev-server`) for JetBrains
Gateway.

## Interface

- `10_register_intellij.sh`: User-setup hook script in
  `/google/scripts/user-setup.d`.
- `WORKSTATION_USER`: Environment variable (defaults to `'user'`).

## Invariants

- Executes under bash strict mode (`set -euo pipefail`).
- Checks that `/opt/ideaIU/bin/remote-dev-server` exists and is executable
  before attempting registration.
- Non-zero exit codes from `registerBackendLocationForGateway` are suppressed
  (`|| true`) so hook failure does not abort user setup.

## Side Effects

- Spawns a login shell as `${WORKSTATION_USER:-user}` via `runuser -l` to
  execute `/opt/ideaIU/bin/remote-dev-server
registerBackendLocationForGateway`, registering the IntelliJ-Ultimate
  backend in the target user's home directory for JetBrains Gateway discovery.
