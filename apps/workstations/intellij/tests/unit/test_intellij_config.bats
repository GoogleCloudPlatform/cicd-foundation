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

setup() {
  load "test_helper.bash"
}

@test "Dockerfile uses predefined intellij-ultimate base image" {
  local dockerfile="${LAYER_DIR}/Dockerfile"
  [ -f "${dockerfile}" ]
  grep -q "FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest" "${dockerfile}"
}

@test "Dockerfile sets SSH client protocol and startup redirect" {
  local dockerfile="${LAYER_DIR}/Dockerfile"
  [ -f "${dockerfile}" ]
  grep -q 'DEFAULT_CLIENT_PROTOCOL="SSH"' "${dockerfile}"
  grep -q 'SUPPORTED_PROTOCOLS="SSH"' "${dockerfile}"
  grep -q 'DEFAULT_REDIRECT_PATH="/startup.html"' "${dockerfile}"
}

@test "backend-readiness drop-in configures port 22" {
  local readiness_conf="${LAYER_DIR}/assets/etc/systemd/system/backend-readiness.service.d/10-intellij.conf"
  [ -f "${readiness_conf}" ]
  grep -q 'BACKEND_WAIT_PORTS=22' "${readiness_conf}"
}

@test "skaffold.yaml defines intellij artifact" {
  local skaffold_file="${LAYER_DIR}/skaffold.yaml"
  [ -f "${skaffold_file}" ]
  grep -q "name: intellij" "${skaffold_file}"
  grep -q "image: intellij" "${skaffold_file}"
}

@test "01_cleanup_legacy_startup.sh build hook exists and removes legacy startup scripts" {
  local hook_script="${LAYER_DIR}/assets/build-hooks.d/01_cleanup_legacy_startup.sh"
  [ -f "${hook_script}" ]
  [ -x "${hook_script}" ]
  grep -q "rm -f /etc/workstation-startup.d/110_start-intellij-ultimate.sh" "${hook_script}"
  grep -q "/etc/workstation-startup.d/130_jetbrains-ready-server.sh" "${hook_script}"
  grep -q "/etc/workstation-startup.d/020_start-sshd.sh" "${hook_script}"
}

@test "10_register_intellij.sh user setup hook exists and registers backend location" {
  local hook_script="${LAYER_DIR}/assets/google/scripts/user-setup.d/10_register_intellij.sh"
  [ -f "${hook_script}" ]
  [ -x "${hook_script}" ]
  grep -q "runuser -l" "${hook_script}"
  grep -q "remote-dev-server registerBackendLocationForGateway" "${hook_script}"
}
