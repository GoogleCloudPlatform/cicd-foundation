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

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

# Sets up the session environment variables.
setup_environment() {
  local target_user="${1}"
  local target_uid
  target_uid=$(id -u "${target_user}")

  # Ensure the runtime directory is set
  export XDG_RUNTIME_DIR="/run/user/${target_uid}"

  # Ensure D-Bus session bus is available
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${target_uid}/bus"
  fi

  # GNOME Headless Wayland defaults
  export WAYLAND_DISPLAY=wayland-0
  export XDG_SESSION_TYPE=wayland
  export XDG_CURRENT_DESKTOP=ubuntu:GNOME
  export GNOME_SHELL_SESSION_MODE=ubuntu

  # Add Wayland support for common toolkits
  export GDK_BACKEND=wayland
  export QT_QPA_PLATFORM=wayland
  export CLUTTER_BACKEND=wayland
  export SDL_VIDEODRIVER=wayland

  # Conditionally force software rendering if no GPU is detected
  if [[ "${WORKSTATION_GPU_ENABLED}" == "false" ]]; then
    log "No GPU detected. Forcing software rendering (LLVMpipe)."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MESA_LOADER_DRIVER_OVERRIDE=swrast
  fi
}

# Configures RDP using credentials from the ephemeral environment.
configure_rdp() {
  local target_user="${1}"

  # Wait for config rendering to complete (ephemeral.env creation)
  local timeout=60
  local count=0
  until [[ -f "${EPHEMERAL_ENV_PATH}" ]] || (( count >= timeout )); do
    log "Waiting for ephemeral credentials file..."
    sleep 2
    (( count += 2 ))
  done

  if [[ -f "${EPHEMERAL_ENV_PATH}" ]]; then
    # shellcheck disable=SC1091
    source "${EPHEMERAL_ENV_PATH}"
    if [[ -n "${EPHEMERAL_PASS:-}" ]]; then
      log "Configuring RDP credentials for ${target_user}..."
      local grd_cert_dir="/home/${target_user}/.local/share/gnome-remote-desktop"

      # RETRY LOOP: Ensure grdctl can talk to the D-Bus session bus
      local max_retries=60
      local sleep_duration=1
      local retry=0
      until grdctl --headless rdp disable >/dev/null 2>&1 || (( retry >= max_retries )); do
        log "Waiting for RDP control interface (grdctl retry ${retry})..."
        sleep $sleep_duration
        retry=$((retry + 1))
      done

      # Configure credentials with error checking
      grdctl --headless rdp set-tls-key "${grd_cert_dir}/rdp-tls.key" || log "warning: failed to set RDP TLS key"
      grdctl --headless rdp set-tls-cert "${grd_cert_dir}/rdp-tls.crt" || log "warning: failed to set RDP TLS cert"
      grdctl --headless rdp set-credentials "${target_user}" "${EPHEMERAL_PASS}" || log "error: failed to set RDP credentials"
      grdctl --headless rdp set-port 3389 || log "warning: failed to set RDP port"
      grdctl --headless rdp enable || log "error: failed to enable RDP"
      grdctl --headless rdp disable-view-only || log "warning: failed to disable view-only mode"

      log "RDP credentials synchronized."
    else
      log "error: EPHEMERAL_PASS not found in ephemeral.env."
    fi
  else
    log "error: ${EPHEMERAL_ENV_PATH} not found after timeout. RDP configuration will likely fail."
  fi
}

main() {
  local target_user="${1:-$WORKSTATION_USER}"

  log_event SERVICE_STARTING "Starting headless GNOME session" SERVICE=gnome-session
  setup_environment "${target_user}"

  # Thoroughly clean up any stale session/D-Bus state for this user
  pkill -9 -u "${target_user}" gnome-session || true
  pkill -9 -u "${target_user}" gnome-shell || true
  pkill -9 -u "${target_user}" gnome-remote-de || true
  # Do NOT kill the user's D-Bus bus itself if possible, but clear the session bus if needed
  # pkill -9 -u "${target_user}" dbus-daemon || true

  /usr/libexec/gnome-session-binary --session=ubuntu &
  local session_pid=$!

  # Wait for shell readiness via D-Bus
  until gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "Main.sessionMode" >/dev/null 2>&1; do
    log "Waiting for GNOME Shell..."
    sleep 2
    if ! kill -0 "${session_pid}" 2>/dev/null; then
      log "GNOME Session failed to start."
      exit 1
    fi
  done
  log "GNOME Shell is ready."

  # CRITICAL: Configure RDP AFTER Shell is ready (so D-Bus is available)
  # then let grdctl handle the configuration.
  configure_rdp "${target_user}"

  log "Starting GNOME Remote Desktop daemon..."
  # Clean up any stale PIDs to avoid bus name conflicts
  pkill -9 -u "${target_user}" gnome-remote-de || true
  sleep 1

  /usr/libexec/gnome-remote-desktop-daemon --headless &
  local grd_pid=$!

  # Wait for daemon readiness via D-Bus
  until gdbus introspect --session --dest org.gnome.RemoteDesktop.Headless --object-path /org/gnome/RemoteDesktop >/dev/null 2>&1; do
    log "Waiting for GNOME Remote Desktop daemon..."
    sleep 2
    if ! kill -0 "${grd_pid}" 2>/dev/null; then
      log "error: GNOME Remote Desktop daemon failed to start."
      break
    fi
  done

  log_event SERVICE_READY "GNOME session is active" SERVICE=gnome-session

  # Wait for the session to exit
  # IMPORTANT: We MUST wait for the background process or the script exits,
  # causing systemd to restart it.
  wait "${session_pid}"
  kill "${grd_pid}" 2>/dev/null || true
}

main "$@"
