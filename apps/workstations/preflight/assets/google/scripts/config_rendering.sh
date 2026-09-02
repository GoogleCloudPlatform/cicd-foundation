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
# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
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

  # Derive routing natively from the requested proxy path without hardcoding image aliases
  export BACKEND_PROXY_PATH="${BACKEND_PROXY_PATH:-/guacamole/}"
  export BACKEND_PROXY_URL="${BACKEND_PROXY_URL:-http://127.0.0.1:8080}"

  # Protocol Logic
  local supported_protocols
  export VNC_XML_BLOCK=""

  if [[ "${DEFAULT_CLIENT_PROTOCOL:-}" == "SSH" || "${DEFAULT_PROTOCOL:-}" == "SSH" ]]; then
    supported_protocols="${SUPPORTED_PROTOCOLS:-SSH}"
    export DEFAULT_CLIENT_PROTOCOL="SSH"
    export DEFAULT_REDIRECT_URL="${DEFAULT_REDIRECT_PATH:-/startup.html}"
    export AUTO_REDIRECT="${AUTO_REDIRECT:-false}"
  elif [[ "${BACKEND_PROXY_PATH}" == "/" || "${DEFAULT_CLIENT_PROTOCOL:-}" =~ ^(HTTP|HTTPS)$ || "${DEFAULT_PROTOCOL:-}" =~ ^(HTTP|HTTPS)$ ]]; then
    supported_protocols="${SUPPORTED_PROTOCOLS:-HTTP,SSH}"
    export DEFAULT_CLIENT_PROTOCOL="${DEFAULT_CLIENT_PROTOCOL:-${DEFAULT_PROTOCOL:-HTTP}}"
    export DEFAULT_REDIRECT_URL="${DEFAULT_REDIRECT_PATH:-/}"
    export AUTO_REDIRECT="${AUTO_REDIRECT:-true}"
  else
    supported_protocols="${SUPPORTED_PROTOCOLS:-RDP,SSH}"
    if [[ "${ENABLE_TIGERVNC:-false}" == "true" ]]; then
      supported_protocols="${supported_protocols},VNC"
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
    export DEFAULT_CLIENT_PROTOCOL="${DEFAULT_PROTOCOL:-${DEFAULT_CLIENT_PROTOCOL:-RDP}}"
    local guac_identifier
    guac_identifier=$(echo -ne "${DEFAULT_CLIENT_PROTOCOL}\0c\0default" | base64 | tr -d '\n=')
    export DEFAULT_REDIRECT_URL="/guacamole/#/client/${guac_identifier}"
    export AUTO_REDIRECT="${AUTO_REDIRECT:-true}"
  fi
  export SUPPORTED_PROTOCOLS="${supported_protocols}"

  # Technical metadata for the preflight page
  export HOSTNAME="$(hostname)"
  export TIMEOUT_MS="${DEFAULT_TIMEOUT_MS:-200000}"

  # Attempt to detect Cloud Workstations instance metadata from GCP metadata server or resource name
  local meta_project=""
  local meta_region=""
  local meta_endpoint=""

  # Attempt to extract project, region, cluster, config, and workstation name from Cloud Workstations resource name
  local res_name="${CLOUD_WORKSTATIONS_WORKSTATION_RESOURCE_NAME:-}"
  if [[ -z "${res_name}" && -f "/etc/environment" ]]; then
    res_name=$(grep -E '^CLOUD_WORKSTATIONS_WORKSTATION_RESOURCE_NAME=' /etc/environment | cut -d'=' -f2- | tr -d '"' | tr -d "'") || true
  fi
  if [[ -z "${res_name}" && -r "/proc/1/environ" ]]; then
    res_name=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep -E '^CLOUD_WORKSTATIONS_WORKSTATION_RESOURCE_NAME=' | cut -d'=' -f2-) || true
  fi
  if [[ -n "${res_name}" ]]; then
    if [[ "${res_name}" =~ projects/([^/]+)/locations/([^/]+)/workstationClusters/([^/]+)/workstationConfigs/([^/]+)/workstations/([^/]+) ]]; then
      meta_project="${BASH_REMATCH[1]}"
      meta_region="${BASH_REMATCH[2]}"
      export CLUSTER_NAME="${CLUSTER_NAME:-${BASH_REMATCH[3]}}"
      export CONFIG_NAME="${CONFIG_NAME:-${BASH_REMATCH[4]}}"
      export HOSTNAME="${BASH_REMATCH[5]}"
    fi
  fi

  for ep in "http://metadata.google.internal" "http://169.254.169.254"; do
    if curl -s -f -m 3 -H "Metadata-Flavor: Google" "${ep}/computeMetadata/v1/project/project-id" > /tmp/cws_proj 2>/dev/null; then
      meta_project=$(cat /tmp/cws_proj)
      rm -f /tmp/cws_proj
      meta_endpoint="${ep}"
      break
    fi
  done
  if [[ -n "${meta_endpoint}" ]]; then
    if curl -s -f -m 3 -H "Metadata-Flavor: Google" "${meta_endpoint}/computeMetadata/v1/instance/zone" > /tmp/cws_zone 2>/dev/null; then
      meta_region=$(cat /tmp/cws_zone | sed -e 's|.*/zones/||' -e 's|-[a-z]$||')
      rm -f /tmp/cws_zone
    fi
  fi

  export PROJECT_ID="${PROJECT_ID:-${GCP_PROJECT:-${GCP_PROJECT_ID:-${meta_project}}}}"
  export REGION="${REGION:-${GCP_REGION:-${meta_region}}}"
  export CLUSTER_NAME="${CLUSTER_NAME:-${WORKSTATION_CLUSTER:-workstations}}"
  export CONFIG_NAME="${CONFIG_NAME:-${WORKSTATION_CONFIG:-}}"

  # Guacamole presence detection
  local has_guacamole="false"
  if [[ -d "/etc/guacamole" || -f "/etc/systemd/system/guacd.service" ]]; then
    has_guacamole="true"
  fi
  export HAS_GUACAMOLE="${HAS_GUACAMOLE:-${has_guacamole}}"

  # SSH port configuration and devcontainer/host separation
  export SSH_PORT="${SSH_PORT:-22}"
  local host_ssh_port=""
  if [[ -f "/opt/devcontainer/intellij/devcontainer.json" || -f "/etc/ssh/sshd_config.d/20-port.conf" ]]; then
    host_ssh_port="2222"
  fi
  export HOST_SSH_PORT="${HOST_SSH_PORT:-${host_ssh_port}}"

  # JetBrains Gateway remote development detection
  local has_gateway="false"
  if [[ -d "/opt/ideaIU" || -f "/opt/devcontainer/intellij/devcontainer.json" || "${CONFIG_NAME}" =~ intellij ]]; then
    has_gateway="true"
  fi
  export HAS_JETBRAINS_GATEWAY="${HAS_JETBRAINS_GATEWAY:-${has_gateway}}"

  # Dynamic Nginx routing based on startup page presence
  if [[ -f "/var/www/html/startup.html" ]]; then
    export ROOT_REDIRECT="/startup.html"
    export PROXY_INTERCEPT_ON_OFF="on"
    export ERROR_PAGE_DIRECTIVE="error_page 502 503 504 =200 /startup.html;"
  else
    export ROOT_REDIRECT="${DEFAULT_REDIRECT_URL}"
    export PROXY_INTERCEPT_ON_OFF="off"
    export ERROR_PAGE_DIRECTIVE=""
  fi

  if [[ "${BACKEND_PROXY_PATH}" == "/" && "${DEFAULT_CLIENT_PROTOCOL}" != "SSH" ]]; then
    # If the app claims the root path explicitly, prevent intercept HTTP 302 loops
    export ROOT_REDIRECT_BLOCK=""
  else
    # Otherwise, proxy is nested or SSH-only. Setup HTTP 302 bounce to Dashboard or UI
    export ROOT_REDIRECT_BLOCK="location = / { return 302 ${ROOT_REDIRECT}; }"
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
$TIMEOUT_MS
$ROOT_REDIRECT
$DEFAULT_REDIRECT_URL
$AUTO_REDIRECT
$PROXY_INTERCEPT_ON_OFF
$ERROR_PAGE_DIRECTIVE
$ROOT_REDIRECT_BLOCK
$WORKSTATION_USER
$RDP_HOST
$RDP_PORT
$SSH_HOST
$SSH_PORT
$BACKEND_PROXY_URL
$BACKEND_PROXY_PATH
$PROJECT_ID
$REGION
$CLUSTER_NAME
$CONFIG_NAME
$HAS_GUACAMOLE
$HOST_SSH_PORT
$HAS_JETBRAINS_GATEWAY
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
