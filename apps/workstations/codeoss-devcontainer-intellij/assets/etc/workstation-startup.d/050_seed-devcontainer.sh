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

seed_devcontainer() {
  local workstation_user="${WORKSTATION_USER:-user}"
  local user_home="/home/${workstation_user}"
  local template_dir="/opt/devcontainer/intellij"

  if [[ ! -d "${user_home}/.devcontainer" && -d "${template_dir}" ]]; then
    mkdir -p "${user_home}/.devcontainer"
    cp -r "${template_dir}/"* "${user_home}/.devcontainer/"
    chown -R "${workstation_user}:${workstation_user}" "${user_home}/.devcontainer"
  fi

  # Enable user lingering so systemd user services start automatically at boot
  mkdir -p /var/lib/systemd/linger
  touch "/var/lib/systemd/linger/${workstation_user}"
}

main() {
  seed_devcontainer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
