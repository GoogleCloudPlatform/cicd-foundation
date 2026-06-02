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

@test "Just Perfection extension is installed and enabled" {
  local ext="just-perfection-desktop@just-perfection"
  run run_ssh "ls /usr/share/gnome-shell/extensions/${ext}/metadata.json"
  [ "$status" -eq 0 ]

  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER bash -c \"export XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$WORKSTATION_UID/bus; gsettings get org.gnome.shell enabled-extensions\" | grep -q '${ext}'"
  [ "$status" -eq 0 ]

  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER bash -c \"export XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$WORKSTATION_UID/bus; gnome-extensions show ${ext}\" | grep -q 'State: ACTIVE'"
  [ "$status" -eq 0 ]
}

@test "Just Perfection indicators are disabled" {
  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER bash -c \"export XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$WORKSTATION_UID/bus; gsettings get org.gnome.shell.extensions.just-perfection screen-sharing-indicator\" | grep -q 'false'"
  [ "$status" -eq 0 ]

  run run_ssh "source /google/scripts/common.sh && sudo -u \$WORKSTATION_USER bash -c \"export XDG_RUNTIME_DIR=/run/user/\$WORKSTATION_UID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$WORKSTATION_UID/bus; gsettings get org.gnome.shell.extensions.just-perfection screen-recording-indicator\" | grep -q 'false'"
  [ "$status" -eq 0 ]
}

@test "Just Perfection CSS is patched for screen-sharing-indicator" {
  local ext="just-perfection-desktop@just-perfection"
  run run_ssh "grep 'GNOME BLUEPRINT PATCH' /usr/share/gnome-shell/extensions/${ext}/stylesheet.css"
  [ "$status" -eq 0 ]
}
