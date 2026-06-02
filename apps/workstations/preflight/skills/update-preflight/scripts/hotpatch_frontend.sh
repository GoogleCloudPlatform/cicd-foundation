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

# This script builds the preflight frontend and syncs it to the live workstation.
# Usage: ./hotpatch_frontend.sh [--wipe] [PROJECT] [REGION]

main() {
  local wipe_flag=false
  if [[ "${1:-}" == "--wipe" ]]; then
    wipe_flag=true
    shift
  fi

  # Support explicit overrides or fall back to env/common.sh defaults
  PROJECT="${1:-${PROJECT}}"
  REGION="${2:-${REGION}}"

  if [[ -z "${WORKSTATION:-}" ]]; then
    error "WORKSTATION environment variable not set. Please load your .env file."
  fi

  log "🔨 Building frontend assets via Vite..."
  local preflight_dir
  preflight_dir="$(cd "${REPO_ROOT}/apps/workstations/preflight-web" && pwd)"
  npm run build --prefix "${preflight_dir}"

  log "🚀 Hot-patching live workstation (${WORKSTATION}) in ${REGION} (Project: ${PROJECT})..."

  local remote_cmd="sudo tar -xzf - -C /var/www/html/ && sudo chown -R root:root /var/www/html/ && sudo find /var/www/html/ -type d -exec chmod 755 {} + && sudo find /var/www/html/ -type f -exec chmod 644 {} +"

  if [ "$wipe_flag" = true ]; then
    log "🧹 Wipe option enabled. Clearing /var/www/html/ before patch..."
    remote_cmd="sudo rm -rf /var/www/html/* && ${remote_cmd} && sudo rm -f /run/config-rendered && sudo /google/scripts/config_rendering.sh"
  fi

  cd "${preflight_dir}/dist"
  tar -czf - . | gcloud workstations ssh "${WORKSTATION}" \
    --project="${PROJECT}" \
    --cluster="${CLUSTER}" \
    --config="${CONFIG}" \
    --region="${REGION}" \
    --command="${remote_cmd}"

  log "✅ Hot-patch complete! Refresh the browser to see changes."
}

main "$@"
