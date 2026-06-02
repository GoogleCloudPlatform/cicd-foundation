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

@test "Antigravity binary is installed" {
  # Check for the wrapper or the direct binary without executing it
  run run_ssh "[ -f /usr/local/bin/antigravity ] || [ -f /usr/share/antigravity/antigravity ]"
  [ "$status" -eq 0 ]
}

@test "Antigravity desktop entry is present" {
  run run_ssh "ls -l /usr/share/applications/antigravity.desktop"
  [ "$status" -eq 0 ]
}

@test "Antigravity is pinned to the dock" {
  assert_app_pinned "antigravity"
}

@test "Antigravity is registered for autostart" {
  assert_app_autostarted "antigravity"
}
