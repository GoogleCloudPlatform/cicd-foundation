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

load ../test_helper.bash

setup() {
  export WORKSTATION_USER=user
  export WORKSTATION_UID=1000

  # Mock common.sh functions
  log() { echo "LOG: $*"; }
  log_event() { echo "LOG_EVENT: $*"; }
  sleep() { echo "MOCK_SLEEP: $*"; }
  export -f log log_event sleep

  # Mock external commands used in the runuser block
  runuser() {
    echo "MOCK_RUNUSER: $*"
    local cmd_string=""
    local is_heredoc=0
    if [[ "$*" == *"-c "* ]]; then
      cmd_string="${*: -1}"
    else
      cmd_string="$(cat)"
      is_heredoc=1
    fi

    # Extract positional arguments if using bash -s
    local positional_args=()
    if [[ "$*" == *"bash -s"* ]]; then
      # Find bash -s and take everything after it
      local found_s=0
      for arg in "$@"; do
        if [[ "$found_s" -eq 1 ]]; then
          positional_args+=("$arg")
        elif [[ "$arg" == "-s" ]]; then
          found_s=1
        fi
      done
    fi

    # Simulate execution of the heredoc/stdin/cmd by mocking the binaries inside it
    export MOCK_CMD_STRING="$cmd_string"
    bash -c '
      gsettings() { echo "gsettings $*"; }
      gnome-extensions() {
        echo "gnome-extensions $*"
        if [[ "$1" == "list" ]]; then
          echo "just-perfection-desktop@just-perfection"
        fi
      }
      sleep() { echo "sleep $*"; }
      export -f gsettings gnome-extensions sleep
      eval "$MOCK_CMD_STRING"
    ' bash "${positional_args[@]}"
  }

  export -f runuser
}

@test "setup_gnome_settings executes expected gsettings commands" {
  # We need to source a modified version of the script that doesn't try to source /google/scripts/common.sh
  # because that file doesn't exist in the local test environment.
  local test_script="${BATS_FILE_TMPDIR}/test_gnome_setup.sh"
  cp "${SCRIPTS_DIR}/gnome_setup.sh" "${test_script}"
  sed -i 's|source /google/scripts/common.sh||g' "${test_script}"

  source "${test_script}"

  # Mock gnome-extensions and gsettings inside the bash execution
  # This is tricky because setup_gnome_settings calls 'runuser ... -- bash <<EOF'

  run setup_gnome_settings

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Configuring GNOME settings" ]]
  [[ "$output" == *'gsettings set org.gnome.shell disable-user-extensions false'* ]]
  [[ "$output" == *'gsettings set org.gnome.shell.extensions.just-perfection screen-sharing-indicator false'* ]]
  [[ "$output" == *'gsettings set org.gnome.shell.extensions.just-perfection screen-recording-indicator false'* ]]
  [[ "$output" == *'gsettings set org.gnome.shell.extensions.just-perfection startup-status 0'* ]]
  [[ "$output" == *'gsettings set org.gnome.shell.extensions.just-perfection support-notifier-showed-version 999'* ]]
}
