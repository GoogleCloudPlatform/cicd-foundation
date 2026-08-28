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
# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
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

  # Wait for the user D-Bus session socket to become active to avoid race conditions
  local dbus_socket="/run/user/${target_uid}/bus"
  local count=0
  until [[ -S "${dbus_socket}" ]] || (( count >= 10 )); do
    log "Waiting for user D-Bus bus socket: ${dbus_socket}..."
    sleep 0.5
    (( count += 1 ))
  done

  if [[ ! -S "${dbus_socket}" ]]; then
    log "User D-Bus socket not found after timeout. Launching managed session bus daemon..."
    dbus-daemon --session --address="unix:path=${dbus_socket}" --nofork --nopidfile &
    sleep 0.5
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

main() {
  local target_user="${1:-$WORKSTATION_USER}"

  log_event SERVICE_STARTING "Starting headless GNOME session" SERVICE=gnome-session
  setup_environment "${target_user}"

  # Thoroughly clean up any stale session/D-Bus state for this user
  pkill -u "${target_user}" gnome-session || true
  pkill -u "${target_user}" gnome-shell || true
  pkill -u "${target_user}" gnome-remote-de || true
  # Do NOT kill the user's D-Bus bus itself if possible, but clear the session bus if needed
  # pkill -u "${target_user}" dbus-daemon || true

  # SEC-04 Compliance: Headless remote automated workstations utilize a blank password
  # for GNOME Keyring to prevent blocking GUI prompts (e.g. from Chrome, gcloud, VS Code)
  # during automated logins where Unix credentials cannot be passed via PAM.
  local keyring_dir="/home/${target_user}/.local/share/keyrings"
  log "Initializing GNOME keyring directory: ${keyring_dir}..."
  rm -rf "${keyring_dir}"
  mkdir -p "${keyring_dir}"
  echo "login" > "${keyring_dir}/default"
  chown -R "${target_user}:${target_user}" "/home/${target_user}/.local"

  log "Pre-seeding blank password for login keyring..."
  printf '\n' | gnome-keyring-daemon --unlock --components=secrets || log "Warning: failed to unlock keyring daemon"

  /usr/libexec/gnome-session-binary --session=ubuntu &
  local session_pid=$!

  # Wait for shell readiness via D-Bus Properties
  until gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.freedesktop.DBus.Properties.Get org.gnome.Shell ShellVersion >/dev/null 2>&1; do
    log "Waiting for GNOME Shell..."
    sleep 1
    if ! kill -0 "${session_pid}" 2>/dev/null; then
      log "GNOME Session failed to start."
      exit 1
    fi
  done
  log "GNOME Shell is ready."

  # Enable extensions now that GNOME Shell is running
  local ext="just-perfection-desktop@just-perfection"
  if gnome-extensions list 2>/dev/null | grep -q "${ext}"; then
    gnome-extensions enable "${ext}" 2>/dev/null || true
  fi

  log_event SERVICE_READY "GNOME session is active" SERVICE=gnome-session
  systemd-notify --ready || log "Warning: systemd-notify failed"

  # Wait for the session to exit
  # IMPORTANT: We MUST wait for the background process or the script exits,
  # causing systemd to restart it.
  wait "${session_pid}"
}

main "$@"
