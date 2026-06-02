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
setup() { setup_env; }

@test "SSH connection established" {
  run run_ssh "echo 'SSH is reachable.'"
  [ "$status" -eq 0 ]
}

@test "Core systemd services are active" {
  services=("config-rendering" "workstation-startup" "nginx" "guacd" "guacamole" "user-setup" "gnome-session@user")
  for service in "${services[@]}"; do
    run run_ssh "sudo systemctl is-active ${service}.service --quiet"
    [ "$status" -eq 0 ]
  done
}

@test "Required network ports are listening" {
  ports=("3389" "4822" "80")
  for port in "${ports[@]}"; do
    run run_ssh "sudo ss -tulpn | grep -q ':${port}'"
    [ "$status" -eq 0 ]
  done
}

@test "GNOME Remote Desktop daemon is configured and enabled" {
  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID grdctl --headless status --show-credentials | grep -qi 'Status: enabled'"
  [ "$status" -eq 0 ]
}

@test "Expected background binaries are running" {
  expected_binaries=("gnome-shell" "gnome-remote-desktop-daemon" "dockerd" "nginx" "guacd")
  for binary in "${expected_binaries[@]}"; do
    run run_ssh "ps aux | grep \"[${binary:0:1}]${binary:1}\" > /dev/null"
    [ "$status" -eq 0 ]
  done
}
