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

@test "daemon.json exists, is valid JSON, and specifies vfs storage-driver" {
  local daemon_json="${ASSETS_DIR}/etc/docker/daemon.json"
  [ -f "${daemon_json}" ]
  run jq . "${daemon_json}"
  [ "$status" -eq 0 ]

  run jq -r '.["storage-driver"]' "${daemon_json}"
  [ "$status" -eq 0 ]
  [ "$output" = "vfs" ]
}

@test "000_configure-docker.sh exists and is executable" {
  local script="${ASSETS_DIR}/etc/workstation-startup.d/000_configure-docker.sh"
  [ -f "${script}" ]
  [ -x "${script}" ]
}

@test "docker.service systemd unit exists and configures data-root and mtu" {
  local service_file="${ASSETS_DIR}/etc/systemd/system/docker.service"
  [ -f "${service_file}" ]
  run grep -E "ExecStart=/usr/bin/dockerd.*--data-root /home/\.docker_data.*--mtu=1460" "${service_file}"
  [ "$status" -eq 0 ]
}

@test "docker-image-preload.service exists and specifies After=docker.service" {
  local service_file="${ASSETS_DIR}/etc/systemd/system/docker-image-preload.service"
  [ -f "${service_file}" ]
  run grep -q "After=docker.service" "${service_file}"
  [ "$status" -eq 0 ]
  run grep -q "Requires=docker.service" "${service_file}"
  [ "$status" -eq 0 ]
  run grep -q "ExecStart=/google/scripts/load_cached_images.sh" "${service_file}"
  [ "$status" -eq 0 ]
}

@test "load_cached_images.sh exists and is executable" {
  local script="${ASSETS_DIR}/google/scripts/load_cached_images.sh"
  [ -f "${script}" ]
  [ -x "${script}" ]
}
