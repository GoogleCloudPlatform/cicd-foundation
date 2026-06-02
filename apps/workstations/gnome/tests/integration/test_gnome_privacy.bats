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

@test "GNOME screen-sharing-indicator is disabled via extension settings" {
  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID dbus-run-session gsettings get org.gnome.shell.extensions.just-perfection screen-sharing-indicator"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "false" ]]
}

@test "GNOME auto-save-session is enabled" {
  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID dbus-run-session gsettings get org.gnome.SessionManager auto-save-session"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "true" ]]
}

@test "Just Perfection CSS patch is applied to hide indicators" {
  run run_ssh "sudo grep -q 'GNOME BLUEPRINT PATCH: Force hide screen sharing' /usr/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/stylesheet.css"
  [ "$status" -eq 0 ]
}
