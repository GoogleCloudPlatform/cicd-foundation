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

# Code-OSS Devcontainer IntelliJ Scripts (`scripts`)

## Overview

Provides the runtime supervisor script (`start_intellij_devcontainer.sh`)
executed by the `intellij-devcontainer.service` systemd user service to wait for
Docker, load cached container images, and launch the user's IntelliJ
devcontainer via the `devcontainer` CLI.

## Interface

- `start_intellij_devcontainer.sh`: Executable script at
  `/google/scripts/start_intellij_devcontainer.sh`.
- `main`: Entrypoint function in `start_intellij_devcontainer.sh`.
- `WORKSTATION_USER`: Consumed environment variable, defaults to `user`.

## Invariants

- Executes with strict Bash error handling (`set -euo pipefail`).
- Requires `/google/scripts/common.sh` to be present and sourceable for `log`,
  `log_event`, `wait_for_docker`, and `load_cached_images` helpers.
- The Docker daemon must become responsive within 60 seconds (`wait_for_docker
60`), otherwise the script logs an error and exits with status `1`.
- If `/home/${WORKSTATION_USER:-user}/.devcontainer/devcontainer.json` exists,
  the `devcontainer` CLI binary must be available in `PATH` or the script
  exits with status `1`.
- If `/home/${WORKSTATION_USER:-user}/.devcontainer/devcontainer.json` does
  not exist, devcontainer launch is skipped and the script exits cleanly
  (status `0`).

## Side Effects

- Sources `/google/scripts/common.sh`, exporting workstation environment
  defaults and GPU detection variables.
- Polls `docker info` for up to 60 seconds via `wait_for_docker`.
- Loads any pre-cached Docker image tarballs from `/opt/images/*.tar` into the
  local Docker daemon via `load_cached_images "/opt/images"`.
- Executes `devcontainer up --workspace-folder
"/home/${WORKSTATION_USER:-user}"` to build/start the IntelliJ devcontainer
  when `.devcontainer/devcontainer.json` is present.
- Emits standard log messages and the `DEVCONTAINER_READY` structured JSON
  event (`log_event DEVCONTAINER_READY "IntelliJ Devcontainer is active"`) to
  stdout.
