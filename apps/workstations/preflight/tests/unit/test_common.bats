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

load test_helper.bash

setup() {
  source "${SCRIPTS_DIR}/common.sh"
}

@test "log output contains message and hostname" {
  run log "This is a test message"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "This is a test message" ]]
  [[ "$output" =~ $(hostname) ]]
}

@test "GPU detection sets WORKSTATION_GPU_ENABLED" {
  # The variable should be defined
  [ -n "${WORKSTATION_GPU_ENABLED}" ]
  # In a test environment without hardware, it should default to false
  # unless specifically mocked.
  if [[ ! -d "/dev/dri" && ! -e "/dev/nvidia0" ]]; then
    [ "${WORKSTATION_GPU_ENABLED}" == "false" ]
  else
    [ "${WORKSTATION_GPU_ENABLED}" == "true" ]
  fi
}
