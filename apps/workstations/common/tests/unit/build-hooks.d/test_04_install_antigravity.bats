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

# shellcheck disable=SC2329

load ../test_helper.bash

setup() {
  # Mock external commands
  chmod() { echo "MOCK_CHMOD: $*"; }
  antigravity() { echo "MOCK_ANTIGRAVITY: $*"; } # Mock the antigravity command
  pipx() { echo "MOCK_PIPX: $*"; }

  export -f chmod antigravity pipx
  export INSTALL_ANTIGRAVITY_SDK="false"

  # Source the script under test
  # shellcheck source=/dev/null
  source "${HOOKS_DIR}/04_install_antigravity.sh"
}

@test "install_antigravity calls chmod on antigravity-cli" {
  run install_antigravity

  [ "$status" -eq 0 ]
  [[ "$output" == *"MOCK_CHMOD: +x /usr/local/bin/antigravity-cli"* ]]
}
