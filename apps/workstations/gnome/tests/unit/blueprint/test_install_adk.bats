#!/usr/bin/env bats

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

load ../test_helper.bash

setup() {
  # Mock pipx
  pipx() {
    echo "MOCK_PIPX: $*"
  }
  export -f pipx
}

@test "05_install_adk.sh installs google-adk when enabled is true" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="true"
  run bash "${HOOKS_DIR}/05_install_adk.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Agent Development Kit" ]]
  [[ "$output" =~ "MOCK_PIPX: install google-adk" ]]
}

@test "05_install_adk.sh skips installation when enabled is false" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="false"
  run bash "${HOOKS_DIR}/05_install_adk.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Agent Development Kit installation skipped" ]]
  [[ ! "$output" =~ "MOCK_PIPX" ]]
}
