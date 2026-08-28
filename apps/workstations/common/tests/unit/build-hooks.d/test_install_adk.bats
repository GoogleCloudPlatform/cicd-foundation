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

# shellcheck disable=SC2329
setup() {
  # Mock external commands
  pipx() { echo "MOCK_PIPX: $*"; }
  mkdir() { echo "MOCK_MKDIR: $*"; }
  git() { echo "MOCK_GIT: $*"; }
  curl() { echo "MOCK_CURL: $*"; }
  tar() { echo "MOCK_TAR: $*"; }
  rm() { echo "MOCK_RM: $*"; }
  export -f pipx mkdir git curl tar rm

  # source the script
  # shellcheck source=/dev/null
  source "${HOOKS_DIR}/05_install_adk.sh"
}

@test "05_install_adk.sh installs google-adk when enabled is true" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="true"
  run install_adk
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Agent Development Kit" ]]
  [[ "$output" =~ "MOCK_MKDIR" ]]
  [[ "$output" =~ "MOCK_CURL" ]]
}

@test "05_install_adk.sh skips installation when enabled is false" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="false"
  run install_adk
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Installing Agent Development Kit" ]]
  [[ ! "$output" =~ "MOCK_MKDIR" ]]
}
