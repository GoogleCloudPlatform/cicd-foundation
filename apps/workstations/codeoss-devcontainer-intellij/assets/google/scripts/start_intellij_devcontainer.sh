#!/bin/bash

# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
source /google/scripts/common.sh

main() {
  log "Starting IntelliJ Devcontainer supervisor..."

  # Wait for Docker daemon to become responsive
  if ! wait_for_docker 60; then
    log "Error: Docker daemon is unavailable, cannot start devcontainer."
    exit 1
  fi

  # Load pre-cached container images
  load_cached_images "/opt/images"

  local user_home="/home/${WORKSTATION_USER:-user}"
  if [[ -f "${user_home}/.devcontainer/devcontainer.json" ]]; then
    log "Launching devcontainer for ${user_home}..."
    if command -v devcontainer >/dev/null 2>&1; then
      devcontainer up --workspace-folder "${user_home}"
      log_event DEVCONTAINER_READY "IntelliJ Devcontainer is active"
    else
      log "Error: devcontainer CLI is not installed."
      exit 1
    fi
  else
    log "No .devcontainer found in ${user_home}, skipping auto-start."
  fi
}

main "$@"
