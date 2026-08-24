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

# This script configures GNOME Remote Desktop RDP settings before daemon startup.

set -euo pipefail

# Source common utilities
# shellcheck source=apps/workstations/base/assets/google/scripts/common.sh
source /google/scripts/common.sh

main() {
  local target_user="${1:-$WORKSTATION_USER}"
  local target_uid
  target_uid=$(id -u "${target_user}")

  export XDG_RUNTIME_DIR="/run/user/${target_uid}"
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${target_uid}/bus"
  fi

  # Wait for ephemeral credentials file
  local timeout=60
  local count=0
  until [[ -f "${EPHEMERAL_ENV_PATH}" ]] || (( count >= timeout )); do
    log "Waiting for ephemeral credentials file..."
    sleep 1
    (( count += 1 ))
  done

  if [[ ! -f "${EPHEMERAL_ENV_PATH}" ]]; then
    log "error: ${EPHEMERAL_ENV_PATH} not found after timeout."
    exit 1
  fi

  # shellcheck source=/dev/null
  source "${EPHEMERAL_ENV_PATH}"

  if [[ -z "${EPHEMERAL_PASS:-}" ]]; then
    log "error: EPHEMERAL_PASS not found in ephemeral.env."
    exit 1
  fi

  local grd_cert_dir="/home/${target_user}/.local/share/gnome-remote-desktop"
  mkdir -p "${grd_cert_dir}"

  # Ensure TLS certificates exist
  if [[ ! -f "${grd_cert_dir}/rdp-tls.crt" ]] || [[ ! -f "${grd_cert_dir}/rdp-tls.key" ]]; then
    local make_cert
    make_cert=$(command -v winpr-makecert3 || command -v winpr3-makecert || command -v winpr-makecert || true)
    if [[ -n "${make_cert}" ]]; then
      log "Generating RDP TLS certificate in ${grd_cert_dir}..."
      "${make_cert}" -silent -rdp -path "${grd_cert_dir}" rdp-tls
      for f in "${grd_cert_dir}"/rdp-tls.*; do
        if [[ -f "$f" ]]; then
          tr -d '\0' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        fi
      done
    fi
  fi

  # RETRY LOOP: Ensure grdctl can talk to the D-Bus session bus
  if command -v grdctl >/dev/null 2>&1; then
    local max_retries=30
    local sleep_duration=1
    local retry=0
    until grdctl --headless rdp disable >/dev/null 2>&1 || (( retry >= max_retries )); do
      log "Waiting for RDP control interface (grdctl retry ${retry})..."
      sleep "${sleep_duration}"
      retry=$((retry + 1))
    done

    log "Configuring RDP via grdctl..."
    grdctl --headless rdp set-tls-key "${grd_cert_dir}/rdp-tls.key" || log "warning: failed to set RDP TLS key"
    grdctl --headless rdp set-tls-cert "${grd_cert_dir}/rdp-tls.crt" || log "warning: failed to set RDP TLS cert"
    grdctl --headless rdp set-credentials "${target_user}" "${EPHEMERAL_PASS}" || log "error: failed to set RDP credentials"
    grdctl --headless rdp set-port 3389 || log "warning: failed to set RDP port"
    grdctl --headless rdp enable || log "error: failed to enable RDP"
    grdctl --headless rdp disable-view-only || log "warning: failed to disable view-only mode"
  fi

  log "RDP pre-configuration complete."
}

main "$@"
