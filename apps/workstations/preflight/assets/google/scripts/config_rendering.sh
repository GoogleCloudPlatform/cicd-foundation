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

# This script handles the generation of ephemeral credentials for the
# session and renders them into configuration file templates.

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

# Generates random ephemeral credentials and exports them.
generate_credentials() {
  local ephemeral_pass
  ephemeral_pass=$(openssl rand -hex 16)
  export EPHEMERAL_PASS="${ephemeral_pass}"
  # Authenticate as the workstation user
  export AUTH_HEADER=$(echo -n "${WORKSTATION_USER}:${EPHEMERAL_PASS}" | base64 | tr -d '\n')
}

# Saves credentials to a sourceable file for other scripts.
save_credentials() {
  log "Creating ephemeral credentials file..."
  mkdir -p "${EPHEMERAL_ENV_DIR}"

  # Ensure the directory is accessible to the user group
  chown root:"${WORKSTATION_UID}" "${EPHEMERAL_ENV_DIR}"
  chmod 750 "${EPHEMERAL_ENV_DIR}"

  # Create the file and set ownership with restricted permissions.
  install -m 640 -o root -g "${WORKSTATION_UID}" /dev/null "${EPHEMERAL_ENV_PATH}"
  cat <<EOV > "${EPHEMERAL_ENV_PATH}"
EPHEMERAL_PASS="${EPHEMERAL_PASS}"
AUTH_HEADER="${AUTH_HEADER}"
EOV
}

# Renders configuration templates using envsubst.
render_templates() {
  local template_files=(
    "/etc/guacamole/user-mapping.xml"
    "/etc/nginx/sites-available/default"
    "/var/www/html/config.js"
  )

  # Support legacy environment variables if set in Dockerfile
  export ENABLE_AUDIO_INPUT="${DEFAULT_ENABLE_AUDIO_INPUT:-false}"

  # Protocol Logic
  local supported_protocols="RDP,SSH"
  export SUPPORTED_PROTOCOLS="${supported_protocols}"
  export VNC_XML_BLOCK=""

  if [[ "${ENABLE_TIGERVNC:-false}" == "true" ]]; then
    supported_protocols="${supported_protocols},VNC"
    export SUPPORTED_PROTOCOLS="${supported_protocols}"
    export VNC_XML_BLOCK="$(cat <<EOV
        <!-- VNC Connection -->
        <connection name="VNC">
            <protocol>vnc</protocol>
            <param name="hostname">${RDP_HOST}</param>
            <param name="port">5901</param>
            <param name="password">${EPHEMERAL_PASS}</param>
        </connection>
EOV
)"
  fi

  # Default to RDP for the client protocol if not explicitly set
  export DEFAULT_CLIENT_PROTOCOL="${DEFAULT_PROTOCOL:-RDP}"

  # Technical metadata for the preflight page
  export HOSTNAME="$(hostname)"
  export UPLINK="${DEFAULT_CLIENT_PROTOCOL}"
  export TIMEOUT_MS="${DEFAULT_TIMEOUT_MS:-200000}"

  # Dynamic Nginx routing based on startup page presence
  if [[ -f "/var/www/html/startup.html" ]]; then
    export ROOT_REDIRECT="/startup.html"
    export PROXY_INTERCEPT_ON_OFF="on"
    export ERROR_PAGE_DIRECTIVE="error_page 502 503 504 =302 /startup.html;"
  else
    export ROOT_REDIRECT="\$default_redirect"
    export PROXY_INTERCEPT_ON_OFF="off"
    export ERROR_PAGE_DIRECTIVE=""
  fi

  # Validate that the requested protocol is actually supported
  if [[ ! ",${supported_protocols}," == *",${DEFAULT_CLIENT_PROTOCOL},"* ]]; then
    log "Warning: Requested DEFAULT_CLIENT_PROTOCOL (${DEFAULT_CLIENT_PROTOCOL}) is not enabled. Falling back to RDP."
    export DEFAULT_CLIENT_PROTOCOL="RDP"
    export UPLINK="RDP"
  fi

  # Render standard config templates
  local file_path

  read -r -d '' allowed_vars << 'EOV' || true
$AUTH_HEADER
$EPHEMERAL_PASS
$ENABLE_AUDIO_INPUT
$DEFAULT_CLIENT_PROTOCOL
$SUPPORTED_PROTOCOLS
$VNC_XML_BLOCK
$HOSTNAME
$UPLINK
$TIMEOUT_MS
$ROOT_REDIRECT
$PROXY_INTERCEPT_ON_OFF
$ERROR_PAGE_DIRECTIVE
$WORKSTATION_USER
$RDP_HOST
$RDP_PORT
$SSH_HOST
$SSH_PORT
EOV
  # Convert multi-line to single line for envsubst
  allowed_vars=$(echo "$allowed_vars" | tr '\n' ' ')

  for file_path in "${template_files[@]}"; do
    local template_path="${file_path}.template"
    if [[ -f "${template_path}" ]]; then
      log "Rendering template for ${file_path}"
      envsubst "$allowed_vars" < "${template_path}" > "${file_path}"
    else
      log "Warning: Template ${template_path} not found, skipping."
    fi
  done
}

# Ensures that all web assets are world-readable for Nginx (www-data).
fix_web_permissions() {
  log "Fixing permissions for /var/www/html..."
  # Ensure all files are readable and directories are searchable
  find /var/www/html -type d -exec chmod 755 {} +
  find /var/www/html -type f -exec chmod 644 {} +
}

# Ensures that all scripts are readable and executable.
fix_script_permissions() {
  log "Fixing permissions for scripts..."
  # Ensure /google/scripts are executable
  if [[ -d "/google/scripts" ]]; then
    chmod 755 /google/scripts
    chmod 644 /google/scripts/*
    # Re-enable execution for .sh files
    chmod 755 /google/scripts/*.sh || true
  fi

  # Ensure /etc/workstation-startup.d are executable
  if [[ -d "/etc/workstation-startup.d" ]]; then
    chmod 755 /etc/workstation-startup.d
    chmod 644 /etc/workstation-startup.d/*
    chmod 755 /etc/workstation-startup.d/*.sh || true
  fi
}

main() {
  # Avoid re-running if already rendered
  if [[ -f /run/config-rendered ]]; then
    log "Configuration already rendered, skipping."
    exit 0
  fi

  log_event SERVICE_STARTING "Rendering ephemeral configurations" SERVICE=config-rendering
  generate_credentials
  save_credentials
  render_templates
  fix_web_permissions
  fix_script_permissions

  log_event SERVICE_READY "Configurations rendered" SERVICE=config-rendering
  touch /run/config-rendered
}

main "$@"
