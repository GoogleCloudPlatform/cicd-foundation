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

@test "Ephemeral password file permissions are 640 root:user" {
  run run_ssh "source /google/scripts/common.sh && sudo stat -c '%a %U %G' \$EPHEMERAL_ENV_PATH | grep -q '640 root user'"
  [ "$status" -eq 0 ]
}

@test "User home directory is owned by user:user" {
  run run_ssh "source /google/scripts/common.sh && sudo stat -c '%U %G' /home/\$WORKSTATION_USER | grep -q \"\$WORKSTATION_USER \$WORKSTATION_USER\""
  [ "$status" -eq 0 ]
}

@test "User setup marker exists" {
  run run_ssh "sudo test -f /run/user-setup-done"
  [ "$status" -eq 0 ]
}

@test "GNOME Shell is running in headless mode" {
  run run_ssh "ps aux | grep '[g]nome-shell' | grep -q '\-\-headless'"
  [ "$status" -eq 0 ]
}
