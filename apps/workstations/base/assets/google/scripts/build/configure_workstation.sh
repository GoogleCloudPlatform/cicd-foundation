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

# shellcheck source=apps/workstations/base/assets/google/scripts/build/install_functions.sh
source /google/scripts/build/install_functions.sh
# shellcheck source=apps/workstations/base/assets/google/scripts/common.sh
source /google/scripts/common.sh

# Constants for asset locations
readonly SCRIPTS_PATHS="/google/scripts /etc/workstation-startup.d /usr/local/bin"
readonly CONFIG_PATHS="/etc/apt/sources.list.d /etc/apt/keyrings /etc/systemd/user /etc/xdg/autostart /google/templates"

# Helper to apply safe permissions to a set of paths
apply_permissions() {
  local mode="${1}"
  shift
  local paths=("$@")

  for path in "${paths[@]}"; do
    if [ -d "${path}" ]; then
      # Ensure directories are traversable (755)
      chmod 755 "${path}" 2>/dev/null || true
      find "${path}" -type d -exec chmod 755 {} + 2>/dev/null || true
      # Apply specified mode to files
      find "${path}" -type f -exec chmod "${mode}" {} + 2>/dev/null || true
    fi
  done
}

prepare_assets() {
  local hooks_dir="$1"
  local post_hooks_dir="$2"
  log "Applying standard asset permissions..."

  # Ensure core system directories are traversable
  chmod 755 /etc /google /google/scripts /usr/share/applications 2>/dev/null || true

  # 1. Scripts must be executable
  # shellcheck disable=SC2086
  apply_permissions "+x" ${SCRIPTS_PATHS} "${hooks_dir}" "${post_hooks_dir}"

  # 2. Configs and assets should be readable
  # shellcheck disable=SC2086
  apply_permissions "644" ${CONFIG_PATHS}
}

main() {
  local hooks_dir="/build-hooks.d/"
  local post_hooks_dir="/post-install-hooks.d/"
  local skip_apt=false
  local skip_cleanup=false

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --hooks-dir) hooks_dir="$2"; shift ;;
      --post-hooks-dir) post_hooks_dir="$2"; shift ;;
      --skip-apt-update|--skip-apt) skip_apt=true ;;
      --skip-cleanup) skip_cleanup=true ;;
      -*) echo "Unknown parameter passed: $1"; exit 1 ;;
      *) hooks_dir="/build-hooks.d/$1" ;;
    esac
    shift
  done

  log_event BUILD_START "Starting workstation configuration"
  prepare_assets "${hooks_dir}" "${post_hooks_dir}"
  configure_apt

  if [[ "${skip_apt}" != "true" ]]; then
    log "Performing initial package list update and installing core dependencies..."
    apt-get update || true
    install_core_packages
  fi

  purge_and_hold_packages

  # Run registration hooks before primary EXTRA_PKGS package index update
  run_hooks "${hooks_dir}"

  if [[ "${skip_apt}" != "true" ]]; then
    log "Updating package lists for newly registered repositories..."
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
    install_extra_debs
  else
    log "Bypassing recursive APT installations (skip-apt flag active)."
  fi

  # Run post-install hooks for layers that need to patch installed files or install local debs
  run_hooks "${post_hooks_dir}"

  if [[ -f "/google/scripts/build/desktop_integration.sh" ]]; then
    log "Applying desktop integration..."
    # shellcheck source=apps/workstations/remote-desktop/assets/google/scripts/build/desktop_integration.sh
    source /google/scripts/build/desktop_integration.sh
    desktop_apply_integration
  fi

  log "Updating dconf databases..."
  if command -v dconf >/dev/null 2>&1; then
    dconf update
  fi

  log "Enabling embedded system services explicitly..."
  mkdir -p /etc/systemd/system/multi-user.target.wants

  # Guarantee SSH starts automatically for backend_readiness_probe.sh validation
  if [[ -f "/lib/systemd/system/ssh.service" ]]; then
    ln -sf /lib/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service
  elif [[ -f "/etc/systemd/system/ssh.service" ]]; then
    ln -sf /etc/systemd/system/ssh.service /etc/systemd/system/multi-user.target.wants/ssh.service
  fi

  # Auto-enable any locally injected systemd overlays from assets/
  for svc_file in /etc/systemd/system/*.service; do
    if [[ -f "${svc_file}" ]]; then
      svc_name=$(basename "${svc_file}")
      # Only construct a want-mapping if standard systemd metadata declares Install routines
      if grep -q '\[Install\]' "${svc_file}"; then
        ln -sf "${svc_file}" "/etc/systemd/system/multi-user.target.wants/${svc_name}"
      fi
    fi
  done

  log_event BUILD_COMPLETE "Workstation configuration finished"

  if [[ "${skip_cleanup}" != "true" ]]; then
    log "Cleaning up..."
    apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/* "${hooks_dir}" "${post_hooks_dir}"
  else
    log "Skipping cleanup as requested."
  fi
}
main "$@"
