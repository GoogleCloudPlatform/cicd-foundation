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

# common.sh: Centralized logic for scripts.

# 1. Determine Roots (relative to this file: skills/common.sh)
SCRIPT_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
REPO_ROOT="$(cd "${SCRIPT_COMMON_DIR}/.." && pwd)"

# 2. Load environment
if [[ -f "${REPO_ROOT}/.env" ]]; then
    # We want to load .env but NOT overwrite already exported variables.
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      # Skip comments and empty lines
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

      # Trim whitespace from key
      key=$(echo "$key" | xargs)

      # If key is already set in the environment, skip it
      if printenv "$key" >/dev/null 2>&1; then
        continue
      fi

      # Trim whitespace from value and strip potential literal quotes
      # This handles both key=value and key="value" or key='value'
      value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
                                 -e 's/^["'\'']//' -e 's/["'\'']$//')

      export "${key}=${value}"
    done < "${REPO_ROOT}/.env"
fi

# 3. Set fallback regions
# BUILD_REGION falls back to REGION
export BUILD_REGION="${BUILD_REGION:-${REGION:-}}"
# ARTIFACT_REGION falls back to BUILD_REGION, then REGION
export ARTIFACT_REGION="${ARTIFACT_REGION:-${BUILD_REGION:-${REGION:-}}}"

# 4. Helper Functions
log() {
    echo -e "[\033[0;34m$(date +%T)\033[0m] $*"
}

warn() {
    echo -e "[\033[0;33mWARN\033[0m] $*"
}

error() {
    echo -e "[\033[0;31mERROR\033[0m] $*" >&2
    exit 1
}
