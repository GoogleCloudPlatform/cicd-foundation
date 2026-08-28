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

# Source common utilities
# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
source /google/scripts/common.sh

main() {
  local target_user="${WORKSTATION_USER:-user}"
  local timeout="${BACKEND_PROBE_TIMEOUT:-600}"
  local count=0

  log "Waiting for GNOME Remote Desktop to start RDP server (timeout ${timeout}s)..."

  while (( count < timeout )); do
    if journalctl -u "gnome-remote-desktop@${target_user}.service" -n 50 --no-pager 2>/dev/null | grep -qi "RDP server started"; then
      log "GNOME Remote Desktop RDP server confirmed ready."
      exit 0
    fi

    sleep 1
    (( count += 1 ))
  done

  log "Error: GNOME Remote Desktop did not log 'RDP server started' within ${timeout}s"
  exit 1
}

main "$@"
