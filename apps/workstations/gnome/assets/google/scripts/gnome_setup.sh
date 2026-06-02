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

# This script handles GNOME-specific user and session setup tasks.

set -euo pipefail

# Max seconds to wait for gnome-shell to recognize extensions
EXTENSION_READY_TIMEOUT=15

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

# Waits for a GNOME extension to become available in the shell.
wait_for_extension() {
  local ext_id="${1}"
  local start_time
  start_time=$(date +%s)

  log "Waiting for extension ${ext_id} to become available..."
  while true; do
    if runuser -u "${WORKSTATION_USER}" -- bash -c "
      export XDG_RUNTIME_DIR=/run/user/${WORKSTATION_UID}
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${WORKSTATION_UID}/bus
      gnome-extensions list" | grep -q "${ext_id}"; then
      log "Extension ${ext_id} is now available."
      return 0
    fi

    local current_time
    current_time=$(date +%s)
    if (( current_time - start_time > EXTENSION_READY_TIMEOUT )); then
      log "Warning: Timeout waiting for extension ${ext_id}."
      return 1
    fi
    sleep 0.5
  done
}

# Generates RDP TLS certificates if necessary.
setup_rdp_certs() {
  log "Checking RDP TLS certificates..."
  local grd_cert_dir="/home/${WORKSTATION_USER}/.local/share/gnome-remote-desktop"
  if command -v winpr-makecert3 >/dev/null 2>&1 || command -v winpr-makecert >/dev/null 2>&1; then
    if [[ ! -f "${grd_cert_dir}/rdp-tls.crt" ]]; then
      log "Generating new RDP TLS certificate..."
      mkdir -p "${grd_cert_dir}"
      chown -R "${WORKSTATION_UID}:${WORKSTATION_UID}" "/home/${WORKSTATION_USER}/.local"
      local make_cert
      make_cert=$(command -v winpr-makecert3 || command -v winpr3-makecert || command -v winpr-makecert)
      runuser -u "${WORKSTATION_USER}" -- "${make_cert}" -silent -rdp -path "${grd_cert_dir}" rdp-tls

      # Strip trailing null bytes that break some PEM parsers
      for f in "${grd_cert_dir}"/rdp-tls.*; do
        if [[ -f "$f" ]]; then
          tr -d '\0' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        fi
      done

      chown -R "${WORKSTATION_UID}:${WORKSTATION_UID}" "${grd_cert_dir}"
    fi
  fi
}

# Initializes the GNOME keyring with a blank password.
setup_keyring() {
  if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    log "Initializing gnome-keyring..."
    local keyring_dir="/home/${WORKSTATION_USER}/.local/share/keyrings"

    # Nuke old keyrings to avoid stale password issues
    rm -rf "${keyring_dir}"
    mkdir -p "${keyring_dir}"
    chown -R "${WORKSTATION_UID}:${WORKSTATION_UID}" "/home/${WORKSTATION_USER}/.local"

    # Ensure a default keyring exists and is unlocked
    runuser -u "${WORKSTATION_USER}" -- bash -c "
      export HOME=/home/${WORKSTATION_USER}
      export XDG_RUNTIME_DIR=/run/user/${WORKSTATION_UID}
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${WORKSTATION_UID}/bus
      printf '\n' | gnome-keyring-daemon --unlock
    " || true

    chown -R "${WORKSTATION_UID}:${WORKSTATION_UID}" "${keyring_dir}"
  fi
}

# Sets Google Chrome as the default browser.
setup_browser() {
  if [[ ! -f /home/${WORKSTATION_USER}/.config/mimeapps.list ]]; then
    log "Setting google-chrome as default browser..."
    mkdir -p "/home/${WORKSTATION_USER}/.config"
    chown -R "${WORKSTATION_UID}:${WORKSTATION_UID}" "/home/${WORKSTATION_USER}/.config"
    runuser -u "${WORKSTATION_USER}" -- bash -c "
      export HOME=/home/${WORKSTATION_USER}
      xdg-mime default google-chrome.desktop text/html
      xdg-mime default google-chrome.desktop x-scheme-handler/http
      xdg-mime default google-chrome.desktop x-scheme-handler/https
      xdg-mime default google-chrome.desktop x-scheme-handler/about
      xdg-settings set default-web-browser google-chrome.desktop
    "
  fi
}

# Configures GNOME Shell settings.
setup_gnome_settings() {
  log "Configuring GNOME settings..."

  local ext="just-perfection-desktop@just-perfection"
  wait_for_extension "${ext}" || true

  runuser -u "${WORKSTATION_USER}" -- bash -s "${ext}" "${WORKSTATION_UID}" <<'EOF'
    ext_id="${1}"
    uid="${2}"

    export XDG_RUNTIME_DIR="/run/user/${uid}"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus"

    gsettings set org.gnome.shell disable-user-extensions false

    if gnome-extensions list | grep -q "${ext_id}"; then
      echo "Enabling ${ext_id}..."
      gnome-extensions enable "${ext_id}" || true
    fi

    # Standard Workstation UI Tweak
    gsettings set org.gnome.shell.extensions.just-perfection screen-sharing-indicator false
    gsettings set org.gnome.shell.extensions.just-perfection screen-recording-indicator false
    gsettings set org.gnome.shell.extensions.just-perfection startup-status 0
    gsettings set org.gnome.shell.extensions.just-perfection support-notifier-showed-version 999

    gsettings set org.gnome.SessionManager auto-save-session true
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
    gsettings set org.gnome.desktop.session idle-delay 0
    gsettings set org.gnome.desktop.lockdown disable-lock-screen false
EOF
}

main() {
  if [[ -f /run/gnome-setup-done ]]; then
    log "GNOME setup already done, skipping."
    exit 0
  fi

  log_event SERVICE_STARTING "Initializing GNOME workstation environment" SERVICE=gnome-setup

  # Clean up legacy configs
  rm -f "/home/${WORKSTATION_USER}/.config/systemd/user/org.gnome.Shell@wayland.service.d/override.conf"
  rm -f "/home/${WORKSTATION_USER}/.local/share/applications/org.gnome.Shell.desktop"

  setup_rdp_certs
  setup_keyring
  setup_browser
  setup_gnome_settings

  log_event SERVICE_READY "GNOME environment initialized" SERVICE=gnome-setup
  touch /run/gnome-setup-done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
