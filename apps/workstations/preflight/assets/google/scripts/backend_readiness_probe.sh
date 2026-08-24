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

# shellcheck source=apps/workstations/base/assets/google/scripts/common.sh
source /google/scripts/common.sh

check_port() {
  local port=$1
  log "Waiting for port ${port} to become ready..."
  # Wait up to 120 seconds for heavy desktop environments to initialize
  for i in {1..120}; do
    # Dual-stack evaluation: Acknowledge listener binds strictly on IPv4 or IPv6
    if bash -c "</dev/tcp/127.0.0.1/${port}" 2>/dev/null || bash -c "</dev/tcp/::1/${port}" 2>/dev/null; then
      log "Port ${port} is ready."
      return 0
    fi
    sleep 1
  done
  log "Warning: Port ${port} did not become ready in time."
  return 1
}

main() {
  log_event BACKEND_PROBE_STARTING "Initiating backend readiness probes" SERVICE=backend-readiness

  # Always clean up any stale ready files on startup
  rm -f /run/backend_ready

  # Split the space-separated list into an array. Default to 8080 if undefined.
  local wait_ports=(${BACKEND_WAIT_PORTS:-8080})
  
  if [[ "${ENABLE_TIGERVNC:-false}" == "true" ]]; then
    wait_ports+=("5901")
  fi

  if [[ "${ENABLE_SSH:-false}" == "true" ]]; then
    wait_ports+=("22")
  fi

  for port in "${wait_ports[@]}"; do
    check_port "${port}"
  done
  
  # Standardize abstract Systemd synchronization variables safely isolating GNOME/XDG dependencies
  local target_user="${WORKSTATION_USER:-user}"
  local wait_services=(${BACKEND_WAIT_SERVICES:-})
  if [[ ${#wait_services[@]} -gt 0 ]]; then
    for svc in "${wait_services[@]}"; do
      # Interpolate user variables globally for scoped service targets dynamically
      svc="${svc//\$WORKSTATION_USER/$target_user}"
      log "Waiting for service ${svc} to become active..."
      for i in {1..120}; do
        if systemctl is-active "${svc}" >/dev/null 2>&1; then
          log "Service ${svc} is active."
          break
        fi
        sleep 1
      done
    done
  fi

  # Honor settling delay if specified by layer environment
  if [[ -n "${APP_STARTUP_DELAY:-}" && "${APP_STARTUP_DELAY}" -gt 0 ]] 2>/dev/null; then
    log "Waiting ${APP_STARTUP_DELAY}s for settling delay..."
    sleep "${APP_STARTUP_DELAY}"
  fi

  log_event BACKEND_READY "Backend services are fully initialized and listening on required ports." SERVICE=backend-readiness
  touch /run/backend_ready
}

main "$@"
