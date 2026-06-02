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

set -euo pipefail

# Sourced root logic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common.sh"

# This script runs the integration tests against a live Cloud Workstation.
# It requires a configuration file (default: .env).

main() {
  log "======================================"
  log " 🌐 Running Integration Tests"
  log "======================================"

  # Load environment configuration (override default from common.sh if passed)
  export ENV_FILE="${1:-${REPO_ROOT}/.env}"

  if [[ ! -f "${ENV_FILE}" ]]; then
    warn "Skip Integration Tests: '${ENV_FILE}' not found."
    log "   (Integration tests require an active Cloud Workstation instance)"
    exit 0
  fi

  log "Environment configuration: ${ENV_FILE}"
  # shellcheck disable=SC1091
  source "${ENV_FILE}"

  # Execute integration tests via Bats
  if command -v bats > /dev/null 2>&1; then
    log "--- Image Layers ---"
    for layer_dir in "${REPO_ROOT}"/apps/workstations/*; do
      if [[ -d "${layer_dir}/tests/integration/" ]]; then
        image_name=$(basename "${layer_dir}")

        # Logic: Always run gnome (foundation).
        # For others, only run if listed in EXTRA_BINARIES or if it matches the current CONFIG flavor.
        if [[ "${image_name}" == "gnome" ]] || \
           [[ "${EXTRA_BINARIES:-}" == *"${image_name}"* ]] || \
           [[ "${CONFIG:-}" == *"${image_name}"* ]]; then
          log "Testing Layer: ${image_name}"
          bats "${layer_dir}/tests/integration/"
        else
          log "Skipping Layer: ${image_name} (Not active for this workstation)"
        fi
      fi
    done

    log "--- Preflight Module ---"
    bats "${REPO_ROOT}/apps/workstations/preflight/tests/integration/"
  else
    error "'bats' (Bats-core) is not installed. Please install it."
  fi
}

main "$@"
