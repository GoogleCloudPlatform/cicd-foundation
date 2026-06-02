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

# This script handles final dynamic service enablement and starts systemd.

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

# Propagates required environment variables to the systemd manager.
# This ensures ConditionEnvironment= checks work correctly for PID 1.
propagate_env() {
  local env_conf="/etc/systemd/system.conf.d/10-env.conf"
  mkdir -p "$(dirname "${env_conf}")"

  log "Propagating environment variables to systemd manager..."
  {
    echo "[Manager]"
    echo -n "DefaultEnvironment="
    # Capture ENABLE_ and DEFAULT_ variables from the current environment
    env | grep -E '^(ENABLE_|DEFAULT_|GCP_REGION)' | xargs || true
  } > "${env_conf}"
}

main() {
  run_hooks "/etc/workstation-startup.d"
  propagate_env

  # Start systemd with the explicitly defined machine id (inherited from entrypoint)
  log_event SYSTEMD_STARTING "Handing over execution to systemd init"
  exec /sbin/init --system --unit=multi-user.target --machine-id "${MACHINE_ID:-}"
}

main "$@"
