#!/usr/bin/env bash

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

# This helper defines common variables for unit tests.

HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

PROJECT_ROOT="$(find_repo_root "${HELPER_DIR}")"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/skills/common.sh"

export ASFP_LAYER_DIR="$(cd "${HELPER_DIR}/../.." && pwd)"
export HOOKS_DIR="${ASFP_LAYER_DIR}/assets/build-hooks.d"

# Load centralized BATS utilities
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/skills/validate-image-updates/tests/bats_common.bash"
