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

# This script centralizes workstation configuration.
# It can be called by any image layer to perform common setup tasks.

# Source the integration utility
# shellcheck source=/dev/null
source /google/scripts/build/desktop_integration.sh

# Constants for asset locations
readonly SCRIPTS_PATHS="/google/scripts /build-hooks.d /post-install-hooks.d /etc/workstation-startup.d /usr/local/bin"
readonly CONFIG_PATHS="/etc/apt/sources.list.d /etc/apt/keyrings /etc/systemd/user /etc/xdg/autostart /google/templates"

# Helper to apply safe permissions to a set of paths
apply_permissions() {
  local mode="${1}"
  shift
  local paths=("$@")

  for path in "${paths[@]}"; do
    if [ -d "${path}" ]; then
      log "  -> Setting ${mode} on ${path}"
      # Ensure directories are traversable (755)
      chmod 755 "${path}" 2>/dev/null || true
      find "${path}" -type d -exec chmod 755 {} + 2>/dev/null || true
      # Apply specified mode to files
      find "${path}" -type f -exec chmod "${mode}" {} + 2>/dev/null || true
    fi
  done
}

configure_apt() {
  local region="${GCP_REGION:-us-central1}"
  log "Configuring APT repositories for region: ${region}..."

  # Replace default region in all .list files
  sed -i "s/us-central1/${region}/g" /etc/apt/sources.list.d/*.list 2>/dev/null || true
}

prepare_assets() {
  log "Applying standard asset permissions..."

  # Ensure core system directories are traversable
  chmod 755 /etc /google /google/scripts /usr/share/applications 2>/dev/null || true

  # 1. Scripts must be executable
  # shellcheck disable=SC2086
  apply_permissions "+x" ${SCRIPTS_PATHS}

  # 2. Configs and assets should be readable
  # shellcheck disable=SC2086
  apply_permissions "644" ${CONFIG_PATHS}
}

install_packages() {
  if [[ -n "${EXTRA_PKGS:-}" ]]; then
    log "Installing extra packages: ${EXTRA_PKGS}..."
    # shellcheck disable=SC2086
    apt-get install -y --no-install-recommends ${EXTRA_PKGS}
  fi
}

install_debs() {
  if [[ -n "${EXTRA_DEB_URLS:-}" ]]; then
    log "Installing extra .deb packages from URLs..."
    for url in ${EXTRA_DEB_URLS}; do
      local filename=$(basename "${url}")
      log "  -> Downloading and installing ${filename}"
      curl ${CURL_OPTS:--fsSL --retry 3} -O "${url}"
      apt-get install -y ./"${filename}"
      rm "${filename}"
    done
  fi
}

main() {
  # Source common utilities (may need to use absolute path during build)
  # shellcheck source=/dev/null
  source /google/scripts/common.sh

  log_event BUILD_START "Starting workstation configuration"
  prepare_assets
  configure_apt

  # Run registration hooks before any package index update
  run_hooks "/build-hooks.d/"

  log "Updating package lists..."
  # Resilient update: succeeds for base repos even if ar+ repos are currently blocked
  apt-get update || true

  # Ensure artifact registry transport is present if any 'ar+' repos were added
  if grep -q "ar+" /etc/apt/sources.list.d/*.list 2>/dev/null; then
    if ! dpkg -s apt-transport-artifact-registry >/dev/null 2>&1; then
      log "Installing apt-transport-artifact-registry for specialized repositories..."
      apt-get install -y --no-install-recommends apt-transport-artifact-registry
      # Perform the second update ONLY if we just installed the transport
      apt-get update
    fi
  fi

  install_packages
  install_debs

  # Run post-install hooks for layers that need to patch installed files or install local debs
  run_hooks "/post-install-hooks.d/"

  if [[ -f "/google/scripts/build/desktop_integration.sh" ]]; then
    log "Applying desktop integration..."
    # shellcheck source=/dev/null
    source /google/scripts/build/desktop_integration.sh
    desktop_apply_integration
  fi

  log "Updating dconf databases..."
  if command -v dconf >/dev/null 2>&1; then
    dconf update
  fi

  log_event BUILD_COMPLETE "Workstation configuration finished"

  log "Cleaning up..."
  apt-get autoremove -y
  apt-get clean
  rm -rf /var/lib/apt/lists/* /build-hooks.d/ /post-install-hooks.d/
}

main "$@"
