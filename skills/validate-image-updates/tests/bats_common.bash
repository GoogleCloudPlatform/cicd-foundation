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

# bats_common.bash: Common test logic for Bats suites.

# Helper to skip slow tests unless explicitly requested
skip_if_slow() {
  if [[ "${RUN_SLOW_TESTS:-false}" != "true" ]]; then
    skip "Skipping slow test. Set RUN_SLOW_TESTS=true to run."
  fi
}

# Asserts that all .sh files in a directory (and subdirectories) are executable.
# Usage: assert_all_scripts_executable "/path/to/directory"
assert_all_scripts_executable() {
  local target_dir="${1}"
  local fail=0
  local non_executable_scripts=""

  if [[ ! -d "${target_dir}" ]]; then
    echo "Directory not found: ${target_dir}"
    return 1
  fi

  # Find all .sh files that are NOT executable, excluding node_modules
  local found
  found=$(find "${target_dir}" -name "*.sh" -not -path "*/node_modules/*" -not -executable)

  if [[ -n "${found}" ]]; then
    non_executable_scripts="${found}"
    fail=1
  fi

  if [[ "${fail}" -eq 1 ]]; then
    echo "Found non-executable .sh files in ${target_dir}:"
    echo -e "${non_executable_scripts}"
    return 1
  fi
}
