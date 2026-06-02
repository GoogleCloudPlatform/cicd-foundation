#!/bin/bash

# Copyright 2025-2026 Google LLC
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

# This script ensures a consistent machine-id across restarts by
# persisting it in the home directory. This is required for
# services like Chrome Remote Desktop and GNOME settings.

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

readonly MACHINE_ID_FILE="/home/.workstation/machine-id"

main() {
  if [[ -f "${MACHINE_ID_FILE}" ]]; then
    MACHINE_ID=$(<"${MACHINE_ID_FILE}")
    log_event MACHINE_ID_RESTORED "Restored existing machine-id" ID="${MACHINE_ID}"
  else
    # Generate a new machine id if one doesn't exist (first boot)
    MACHINE_ID=$(tr -d '-' < /proc/sys/kernel/random/uuid)
    log_event MACHINE_ID_GENERATED "Generated new machine-id" ID="${MACHINE_ID}"
    mkdir -p "$(dirname "${MACHINE_ID_FILE}")"
    echo "${MACHINE_ID}" > "${MACHINE_ID_FILE}"
  fi

  # Set the machine-id in /etc for systemd and other tools
  echo "${MACHINE_ID}" > /etc/machine-id

  # Export it so the calling script can use it if needed
  export MACHINE_ID
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  main "$@"
else
  # If executed directly, run it but warn it should be sourced.
  main "$@"
fi
