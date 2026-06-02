#!/bin/bash

# Copyright 2025-2026 Google LLC
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

# This script configures and launches the Chrome Remote Desktop service.

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

# Sets up the PKI directory for NSSDB.
setup_pki() {
  local home_dir="${1}"
  local target_user="${2}"
  mkdir -p "${home_dir}/.pki/nssdb"
  chown -R "${target_user}:${target_user}" "${home_dir}/.pki"
  chmod 700 "${home_dir}/.pki"
}

# Ensures the user is part of the chrome-remote-desktop group.
setup_groups() {
  local target_user="${1}"
  groupadd -f chrome-remote-desktop || true
  usermod -aG chrome-remote-desktop "${target_user}"
}

# Starts the CRD service if configuration files are found.
start_service() {
  local target_user="${1}"
  local config_dir="${2}"
  if ls "${config_dir}"/host*.json >/dev/null 2>&1; then
    log_event SERVICE_STARTING "Starting Chrome Remote Desktop Service..." SERVICE=chrome-remote-desktop
    runuser -u "${target_user}" -- bash -c "/opt/google/chrome-remote-desktop/chrome-remote-desktop --start" &
    log_event SERVICE_READY "Chrome Remote Desktop Service started" SERVICE=chrome-remote-desktop
  else
    log "No CRD configuration found. Skipping service start."
  fi
}

main() {
  if ! command -v /opt/google/chrome-remote-desktop/chrome-remote-desktop &> /dev/null; then
    log "Chrome Remote Desktop not installed. Skipping setup."
    exit 0
  fi

  log_event SERVICE_STARTING "Setting up Chrome Remote Desktop..." SERVICE=chrome-remote-desktop
  local target_user="user"
  local home_dir="/home/${target_user}"
  local config_dir="${home_dir}/.config/chrome-remote-desktop"

  setup_pki "${home_dir}" "${target_user}"
  setup_groups "${target_user}"

  # Ensure the system dbus runtime directory exists
  mkdir -p /var/run/dbus

  mkdir -p "${config_dir}"
  chown -R "${target_user}:${target_user}" "${config_dir}"

  start_service "${target_user}" "${config_dir}"
}

main "$@"
