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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common.sh"

main() {
  log "======================================"
  log " 🚀 Running Local Unit Tests"
  log "======================================"

  cd "${REPO_ROOT}"

  # Define the core unit test hooks to execute
  local test_hooks=(
    "bats-skills"
    "pytest-skills"
    "go-test-persona"
    "bats-preflight"
    "bats-preflight-web"
    "npm-install-preflight"
    "vitest"
    "bats-images"
  )

  local pre_commit="pre-commit"
  if ! command -v pre-commit > /dev/null 2>&1; then
    if [[ -x "$HOME/.local/bin/pre-commit" ]]; then
      pre_commit="$HOME/.local/bin/pre-commit"
    else
      error "pre-commit not found. Please install it."
    fi
  fi

  # Execute each test hook individually for clear reporting
  for hook in "${test_hooks[@]}"; do
    log "Running: ${hook}"
    "${pre_commit}" run "${hook}" --all-files
  done

  log "======================================"
  log " 🎉 All local unit tests passed!"
  log "======================================"
}

main "$@"
