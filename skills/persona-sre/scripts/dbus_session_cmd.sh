#!/bin/bash

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

set -euo pipefail

# Sourced root logic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common.sh"

# This script executes a command within the user's D-Bus session.
# It is useful for modifying gsettings or interacting with GNOME extensions via SSH.

usage() {
  echo "Usage: $0 [COMMAND]"
  echo "  Example: $0 'gsettings get org.gnome.desktop.interface cursor-theme'"
  exit 1
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
  fi

  local cmd="$*"

  log "Executing in D-Bus Session: ${cmd}"
  sudo -u user bash -c "export XDG_RUNTIME_DIR=/run/user/1000; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; ${cmd}"
}

main "$@"
