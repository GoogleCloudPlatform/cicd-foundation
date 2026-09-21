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

# This script handles foundational one-time user setup tasks.
# It is designed to be window-manager agnostic.

set -euo pipefail

# Source common utilities
# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
source /google/scripts/common.sh

# Sets up the user-specific runtime directory (XDG_RUNTIME_DIR).
setup_runtime_dir() {
  local xdg_runtime_dir="/run/user/${WORKSTATION_UID}"
  log "Setting up XDG_RUNTIME_DIR at ${xdg_runtime_dir}..."
  mkdir -p "${xdg_runtime_dir}"
  chown "${WORKSTATION_UID}:${WORKSTATION_UID}" "${xdg_runtime_dir}"
  chmod 700 "${xdg_runtime_dir}"
}

# Ensures correct ownership of the user home directory and basic group memberships.
setup_home_dir() {
  log "Fixing ownership for /home/${WORKSTATION_USER}..."

  # Ensure user is in basic functional groups
  usermod -aG audio "${WORKSTATION_USER}" || true

  # Ensure the user can use docker if installed
  if getent group docker >/dev/null; then
    usermod -aG docker "${WORKSTATION_USER}" || true
  fi

  # Only chown entries that are actually mis-owned.
  #
  # A recursive chown rewrites every inode under /home unconditionally, and
  # anything ordered after this unit is blocked until it finishes. On a home
  # directory holding a large source checkout that dominates the boot: on a
  # workstation with 3.2M inodes under /home, and where nothing is actually
  # mis-owned, filtering first took user-setup.service from 6min 15.858s to
  # 3min 53.509s.
  #
  # The cost is also paid on every start rather than once. main() guards on
  # /run/user-setup-done, but /run is tmpfs, so the marker does not survive a
  # shutdown.
  #
  # Filtering preserves the behaviour exactly - this still runs on every boot
  # and still repairs genuinely wrong ownership (the first mount of a freshly
  # created disk, a disk seeded from a snapshot built under a different UID, or
  # an image that renumbers the user) - while only writing when there is
  # something to repair.
  #
  # Use -h to avoid dereferencing symlinks
  find "/home/${WORKSTATION_USER}" \
    \( ! -uid "${WORKSTATION_UID}" -o ! -gid "${WORKSTATION_UID}" \) \
    -exec chown -h "${WORKSTATION_UID}:${WORKSTATION_UID}" {} +
}

# Executes any modular user-level hooks (as root, but can use runuser inside).
run_user_setup_hooks() {
  local hook_dir="/google/scripts/user-setup.d"
  if [[ -d "${hook_dir}" ]]; then
    log "Executing foundational user setup hooks from ${hook_dir}..."
    run_hooks "${hook_dir}"
  fi
}

main() {
  if [[ -f /run/user-setup-done ]]; then
    log "User setup already done, skipping."
    exit 0
  fi

  log_event SERVICE_STARTING "Initializing foundational workstation user" SERVICE=user-setup

  setup_runtime_dir
  setup_home_dir
  run_user_setup_hooks

  log_event SERVICE_READY "Foundational user environment initialized" SERVICE=user-setup
  touch /run/user-setup-done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
