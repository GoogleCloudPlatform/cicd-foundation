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

# Sourced root logic
find_repo_root() {
  local dir="${1}"
  while [[ "${dir}" != "/" ]]; do
    if [[ -f "${dir}/skills/common.sh" ]]; then
      echo "${dir}"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done
  return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(find_repo_root "${SCRIPT_DIR}")"
# shellcheck disable=SC1091
source "${REPO_ROOT}/skills/common.sh"

# This script runs frontend tests and then hot-patches the live workstation.

main() {
  log "======================================"
  log " 🧪 Running Frontend Tests (Vitest)"
  log "======================================"

  local preflight_dir="${REPO_ROOT}/apps/workstations/preflight-web"
  npm test --prefix "${preflight_dir}"

  log "======================================"
  log " 🚀 Deploying to Live Workstation"
  log "======================================"
  "${SCRIPT_DIR}/hotpatch_frontend.sh"
}

main "$@"
