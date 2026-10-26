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

# IntelliJ Build Hooks (`build-hooks.d`)

## Overview

Build hook directory for the IntelliJ Ultimate workstation image containing
`01_cleanup_legacy_startup.sh`, which removes legacy startup scripts inherited
from the predefined IntelliJ Ultimate base image to prevent premature execution
and port conflicts with systemd-managed services.

## Interface

- `01_cleanup_legacy_startup.sh`: Build-time hook script executed via
  `/google/scripts/build/configure_workstation.sh` (`run_hooks`).

## Invariants

- Executes under strict Bash error handling (`set -euo pipefail`).
- Idempotently removes target files using `rm -f` so missing files do not fail
  the build.
- Ensures port `80` is not bound by legacy `130_jetbrains-ready-server.sh`
  (preventing collision with the Nginx preflight dashboard) and port `22` is
  not bound by legacy `020_start-sshd.sh` (preventing conflict with systemd
  `sshd`).
- Prevents `110_start-intellij-ultimate.sh` from running before systemd and
  user setup initialization.

## Side Effects

- Deletes `/etc/workstation-startup.d/110_start-intellij-ultimate.sh` from the
  container filesystem.
- Deletes `/etc/workstation-startup.d/130_jetbrains-ready-server.sh` from the
  container filesystem.
- Deletes `/etc/workstation-startup.d/020_start-sshd.sh` from the container
  filesystem.
