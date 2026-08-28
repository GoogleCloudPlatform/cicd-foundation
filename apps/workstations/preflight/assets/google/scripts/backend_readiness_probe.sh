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

# shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
source /google/scripts/common.sh

READINESS_DIR="/run/readiness"

check_port() {
  local port=$1
  local timeout="${2:-${BACKEND_PROBE_TIMEOUT:-600}}"
  log "Waiting for port ${port} to become ready (timeout ${timeout}s)..."
  for (( i=1; i<=timeout; i++ )); do
    # Dual-stack evaluation: Acknowledge listener binds strictly on IPv4 or IPv6
    if bash -c "</dev/tcp/127.0.0.1/${port}" 2>/dev/null || bash -c "</dev/tcp/::1/${port}" 2>/dev/null; then
      log "Port ${port} is ready."
      return 0
    fi
    sleep 1
  done
  log "Warning: Port ${port} did not become ready in time (${timeout}s)."
  return 1
}

wait_for_service() {
  local svc=$1
  local timeout="${2:-${BACKEND_PROBE_TIMEOUT:-600}}"
  log "Waiting for service ${svc} to become active (timeout ${timeout}s)..."
  for (( i=1; i<=timeout; i++ )); do
    if systemctl is-active "${svc}" >/dev/null 2>&1; then
      log "Service ${svc} is active."
      return 0
    fi
    sleep 1
  done
  log "Error: Service ${svc} did not become active in time (${timeout}s)."
  return 1
}

probe_ssh() {
  log "Starting SSH readiness probe..."
  if check_port 22; then
    echo "OK" > "${READINESS_DIR}/ssh"
    log "Protocol SSH is ready."
    return 0
  fi
  return 1
}

probe_http() {
  local port="${1:-8080}"
  log "Starting HTTP readiness probe on port ${port}..."
  if check_port "${port}"; then
    echo "OK" > "${READINESS_DIR}/http"
    log "Protocol HTTP is ready."
    return 0
  fi
  return 1
}

probe_rdp() {
  local target_user="${1:-user}"
  log "Starting RDP readiness probe..."
  
  # 1. Wait for services to become active first
  local wait_services=(${BACKEND_WAIT_SERVICES:-})
  if [[ ${#wait_services[@]} -gt 0 ]]; then
    for svc in "${wait_services[@]}"; do
      svc="${svc//\$WORKSTATION_USER/$target_user}"
      wait_for_service "${svc}" || return 1
    done
  fi

  # 2. Verify all RDP ports are open: Guacamole web (8080), guacd (4822), and RDP listener (3389)
  check_port 8080 || return 1
  check_port 4822 || return 1
  check_port 3389 || return 1

  # 3. Execute layer readiness probe hook (e.g. authoritative RDP server started check)
  if [[ -x /google/scripts/layer_readiness_probe.sh ]]; then
    log "Executing layer readiness probe hook..."
    if ! /google/scripts/layer_readiness_probe.sh; then
      log "Error: Layer readiness probe hook failed."
      return 1
    fi
  fi

  echo "OK" > "${READINESS_DIR}/rdp"
  log "Protocol RDP is ready."
  return 0
}

probe_vnc() {
  log "Starting VNC readiness probe..."
  check_port 8080 || return 1
  check_port 4822 || return 1
  check_port 5901 || return 1

  echo "OK" > "${READINESS_DIR}/vnc"
  log "Protocol VNC is ready."
  return 0
}

main() {
  log_event BACKEND_PROBE_STARTING "Initiating backend readiness probes" SERVICE=backend-readiness

  # Initialize clean readiness state
  mkdir -p "${READINESS_DIR}"
  rm -f "${READINESS_DIR}"/* /run/backend_ready

  local target_user="${WORKSTATION_USER:-user}"
  local supported="${SUPPORTED_PROTOCOLS:-${DEFAULT_CLIENT_PROTOCOL:-HTTP,SSH}}"
  local wait_ports=(${BACKEND_WAIT_PORTS:-})
  local pids=()

  # 1. SSH Probe (if enabled or supported)
  if [[ "${ENABLE_SSH:-true}" == "true" || "${supported}" =~ SSH || " ${wait_ports[*]} " =~ " 22 " ]]; then
    probe_ssh &
    pids+=($!)
  fi

  # 2. RDP Probe (if RDP is in supported protocols or ports contain 3389)
  if [[ "${supported}" =~ RDP || " ${wait_ports[*]} " =~ " 3389 " ]]; then
    probe_rdp "${target_user}" &
    pids+=($!)
  fi

  # 3. VNC Probe (if TigerVNC is enabled or VNC is supported)
  if [[ "${ENABLE_TIGERVNC:-false}" == "true" || "${supported}" =~ VNC || " ${wait_ports[*]} " =~ " 5901 " ]]; then
    probe_vnc &
    pids+=($!)
  fi

  # 4. HTTP / Web IDE Probe (if HTTP/HTTPS is supported or only 8080 is configured)
  if [[ "${supported}" =~ (HTTP|HTTPS) || (! "${supported}" =~ RDP && ! "${supported}" =~ VNC && " ${wait_ports[*]} " =~ " 8080 ") ]]; then
    probe_http "${wait_ports[0]:-8080}" &
    pids+=($!)
  fi

  # Wait for all background probes to complete
  for pid in "${pids[@]}"; do
    if ! wait "${pid}"; then
      log "Error: A protocol readiness probe failed."
      exit 1
    fi
  done

  # Honor settling delay if specified by layer environment
  if [[ -n "${APP_STARTUP_DELAY:-}" && "${APP_STARTUP_DELAY}" -gt 0 ]] 2>/dev/null; then
    log "Waiting ${APP_STARTUP_DELAY}s for settling delay..."
    sleep "${APP_STARTUP_DELAY}"
  fi

  log_event BACKEND_READY "All backend services and protocols are fully initialized." SERVICE=backend-readiness
  echo "OK" > "${READINESS_DIR}/all"
}

main "$@"
