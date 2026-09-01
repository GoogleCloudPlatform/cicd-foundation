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

load test_helper.bash

setup() {
  # shellcheck source=/dev/null
  source "${SCRIPTS_DIR}/common.sh"
}

@test "log output contains message and hostname" {
  run log "This is a test message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"This is a test message"* ]]
  [[ "$output" == *"$(hostname)"* ]]
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

@test "wait_for_docker returns 0 when docker info succeeds" {
  docker() {
    if [[ "$1" == "info" ]]; then
      return 0
    fi
    return 1
  }
  export -f docker

  run wait_for_docker 5
  [ "$status" -eq 0 ]
  [[ "$output" == *"Docker daemon is ready."* ]]
}

@test "load_cached_images calls docker load on tarballs" {
  local mock_dir="${BATS_TEST_TMPDIR}/images"
  mkdir -p "${mock_dir}"
  touch "${mock_dir}/img1.tar" "${mock_dir}/img2.tar"

  docker() {
    if [[ "$1" == "load" && "$2" == "-i" ]]; then
      return 0
    fi
    return 1
  }
  export -f docker

  run load_cached_images "${mock_dir}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Loading cached container image: ${mock_dir}/img1.tar"* ]]
  [[ "$output" == *"Loading cached container image: ${mock_dir}/img2.tar"* ]]
}
