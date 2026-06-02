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

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common.sh"

main() {
  local sbom_path="${REPO_ROOT}/apps/workstations/preflight-web/public/sbom.json"
  local licenses_dir="${REPO_ROOT}/apps/workstations/preflight-web/public/licenses"
  local helper="${SCRIPT_DIR}/lib/sbom_helper.py"

  log "======================================"
  log " 📦 Syncing SBOM License Assets"
  log "======================================"

  if [[ ! -f "${sbom_path}" ]]; then
    error "SBOM manifest not found at ${sbom_path}"
  fi

  mkdir -p "${licenses_dir}"

  log "🔍 Discovering license mappings via helper..."

  # Read mappings from helper: "lid url local_text"
  local tmp_map
  tmp_map=$(mktemp)
  python3 "${helper}" "${sbom_path}" > "${tmp_map}"

  local lid url local_text
  while read -r lid url local_text; do
    # Skip Unsplash as it is a custom text already present
    if [[ "${lid}" == "Unsplash" ]]; then
      log "⏩ Skipping custom license: ${lid}"
      continue
    fi

    # local_text is relative to public/ e.g. "licenses/MIT.txt"
    local target_file="${REPO_ROOT}/apps/workstations/preflight-web/public/${local_text}"

    log "📥 Fetching ${lid} text from ${url}..."

    if curl -fsSL "${url}" -o "${target_file}"; then
      log "✅ Saved to ${local_text}"
    else
      warn "❌ Failed to download ${lid} from ${url}"
    fi
  done < "${tmp_map}"

  rm -f "${tmp_map}"

  log "✅ License asset synchronization complete."
}

main "$@"
