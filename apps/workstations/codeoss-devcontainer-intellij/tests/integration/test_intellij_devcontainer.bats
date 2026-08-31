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

@test "Host SSH daemon is active on port 2222" {
  run run_ssh "sudo ss -tulpn | grep -q ':2222'"
  [ "$status" -eq 0 ]
}

@test "Code OSS service is active" {
  run run_ssh "sudo systemctl is-active code-oss.service --quiet"
  [ "$status" -eq 0 ]
}

@test "Required web and editor ports are listening" {
  ports=("80" "8080")
  for port in "${ports[@]}"; do
    run run_ssh "sudo ss -tulpn | grep -q ':${port}'"
    [ "$status" -eq 0 ]
  done
}

@test "IntelliJ devcontainer files exist in user workspace" {
  run run_ssh "test -f /home/user/.devcontainer/devcontainer.json && test -f /home/user/.devcontainer/Dockerfile"
  [ "$status" -eq 0 ]
}

@test "Devcontainer configuration specifies port 22 forwarding" {
  run run_ssh "grep -q 'forwardPorts' /home/user/.devcontainer/devcontainer.json && grep -q '22' /home/user/.devcontainer/devcontainer.json"
  [ "$status" -eq 0 ]
}
