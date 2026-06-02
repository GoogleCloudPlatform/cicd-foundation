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

# Sourced root logic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../common.sh"

usage() {
  echo "Usage: $0 [start|stop|restart|wait|ssh|tunnel] [WORKSTATION] [flags/args]"
  echo ""
  echo "Actions:"
  echo "  start   : Starts the workstation and waits for STATE_RUNNING."
  echo "  stop    : Stops the workstation and waits for STATE_STOPPED."
  echo "  restart : Stops and then starts the workstation."
  echo "  wait    : Polls until the workstation reaches a TARGET_STATE (default: STATE_RUNNING)."
  echo "  ssh     : Connects to the workstation via SSH."
  echo "  tunnel  : Establishes an SSH tunnel and optionally opens the workstation URL."
  echo ""
  echo "Arguments/Flags (optional if set in .env):"
  echo "  [WORKSTATION]  Name of the workstation."
  echo "  --target-state Target state for 'wait' action."
  echo "  --project      GCP Project ID."
  echo "  --cluster      Workstation Cluster name."
  echo "  --config       Workstation Config name."
  echo "  --region       GCP Region."
  echo "  --timeout      Timeout in seconds (default: 600)."
  echo "  --local-port   Local port for the SSH tunnel (default: 2222)."
  echo "  --remote-port  Remote port on the workstation (default: 22)."
  echo "  --user         Username for SSH (default: user)."
  echo "  --browser      Open URL in browser. Optional value sets browser (default: google-chrome)."
  echo "  --no-ssh-config Skip updating ~/.ssh/config for the 'ws' host."
  exit 1
}

# Helper: Retrieve the workstation hostname
get_ws_host() {
  local workstation="$1"
  local project="$2"
  local cluster="$3"
  local config="$4"
  local region="$5"

  gcloud workstations describe "${workstation}" \
    --project="${project}" --cluster="${cluster}" \
    --config="${config}" --region="${region}" \
    --format="value(host)"
}

# Helper: Open a URL in a specified browser or system default
open_browser_url() {
  local url="$1"
  local browser="$2"

  if [[ -z "${browser}" ]]; then
    return 0
  fi

  log "Opening ${url}..."
  if command -v "${browser}" >/dev/null 2>&1; then
    "${browser}" "${url}" &
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "${url}" &
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "${url}" &
  else
    warn "Unable to find browser ${browser}. Please open ${url} manually."
  fi
}

# Wait for a workstation to reach a specific state with a timeout.
wait_for_ws_state() {
    local ws_name="$1"
    local target_state="$2"
    local project="${3:-${PROJECT:-}}"
    local cluster="${4:-${CLUSTER:-}}"
    local config="${5:-${CONFIG:-}}"
    local region="${6:-${REGION:-}}"
    local timeout_seconds="${7:-600}"

    if [[ -z "${ws_name}" || -z "${project}" || -z "${cluster}" || -z "${config}" || -z "${region}" ]]; then
        error "wait_for_ws_state: Missing required parameters (WS, Project, Cluster, Config, Region)."
    fi

    log "Waiting for ${ws_name} to reach ${target_state} (timeout: ${timeout_seconds}s)..."

    local start_time
    start_time=$(date +%s)
    local last_logged_state=""

    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ ${elapsed} -ge ${timeout_seconds} ]]; then
            error "Timeout reached (${timeout_seconds}s) waiting for ${ws_name} to reach ${target_state}."
        fi

        local state
        if ! state=$(gcloud workstations describe "${ws_name}" \
            --project="${project}" --cluster="${cluster}" \
            --config="${config}" --region="${region}" \
            --format="value(state)" 2>/dev/null); then
            warn "Failed to fetch state for ${ws_name}. (Gcloud error, retrying...)"
        else
            if [[ "${state}" == "${target_state}" ]]; then
                log "✅ Workstation ${ws_name} reached ${state}."
                return 0
            fi

            if [[ "${state}" != "${last_logged_state}" ]]; then
                log "Workstation ${ws_name} is currently ${state:-UNKNOWN}..."
                last_logged_state="${state}"
            fi
        fi

        sleep 10
    done
}

start_ws() {
  local workstation="$1"
  local project="$2"
  local cluster="$3"
  local config="$4"
  local region="$5"
  local timeout="$6"
  local browser="$7"

  # Check current state first to avoid redundant start commands
  local state
  state=$(gcloud workstations describe "${workstation}" \
    --project="${project}" --cluster="${cluster}" \
    --config="${config}" --region="${region}" \
    --format="value(state)" 2>/dev/null || echo "UNKNOWN")

  if [[ "${state}" != "STATE_RUNNING" ]]; then
    log "--- Starting Workstation: ${workstation} ---"
    gcloud workstations start "${workstation}" \
      --project="${project}" --cluster="${cluster}" \
      --config="${config}" --region="${region}"

    wait_for_ws_state "${workstation}" "STATE_RUNNING" "${project}" "${cluster}" "${config}" "${region}" "${timeout}"
  else
    log "Workstation ${workstation} is already running."
  fi

  # Optionally open browser
  if [[ -n "${browser}" ]]; then
    local ws_host
    ws_host=$(get_ws_host "${workstation}" "${project}" "${cluster}" "${config}" "${region}")
    if [[ -n "${ws_host}" ]]; then
      open_browser_url "https://${ws_host}" "${browser}"
    else
      warn "Unable to lookup hostname for ${workstation}. Skipping browser open."
    fi
  fi
}

stop_ws() {
  local workstation="$1"
  local project="$2"
  local cluster="$3"
  local config="$4"
  local region="$5"
  local timeout="$6"

  log "--- Stopping Workstation: ${workstation} ---"
  gcloud workstations stop "${workstation}" \
    --project="${project}" --cluster="${cluster}" \
    --config="${config}" --region="${region}"

  wait_for_ws_state "${workstation}" "STATE_STOPPED" "${project}" "${cluster}" "${config}" "${region}" "${timeout}"
}

tunnel_ws() {
  local workstation="$1"
  local project="$2"
  local cluster="$3"
  local config="$4"
  local region="$5"
  local timeout="$6"
  local local_port="$7"
  local remote_port="$8"
  local browser="$9"
  local manage_ssh_config="${10}"
  local user="${11}"

  # 1. Ensure Running and handle browser
  start_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" "${browser}"

  # 2. Manage SSH Config
  if [[ "${manage_ssh_config}" == "true" ]]; then
    local ssh_config="$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh"
    touch "${ssh_config}"

    if ! grep -q "^Host ws$" "${ssh_config}"; then
      log "Creating 'ws' host entry in ${ssh_config}..."
      cat >> "${ssh_config}" <<EOF

Host ws
  HostName 127.0.0.1
  Port ${local_port}
  User ${user}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
      log "✅ Added 'ws' entry to SSH config."
    else
      log "SSH config already contains 'ws' entry. Skipping."
    fi
  fi

  # 3. Establish Tunnel
  log "Starting SSH tunnel on local port ${local_port} -> remote port ${remote_port}..."
  log "You can ssh into your workstation with 'ssh ws' (if using default config)."

  # Note: start-tcp-tunnel is the command for the current gcloud version
  gcloud workstations start-tcp-tunnel "${workstation}" "${remote_port}" \
    --local-host-port="localhost:${local_port}" \
    --project="${project}" --cluster="${cluster}" \
    --config="${config}" --region="${region}"
}

ssh_ws() {
  local workstation="$1"
  local project="$2"
  local cluster="$3"
  local config="$4"
  local region="$5"
  local timeout="$6"
  local remote_port="$7"
  local user="$8"

  # 1. Ensure Running
  start_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" ""

  # 2. Connect via SSH
  log "SSHing into workstation ${workstation}..."
  gcloud workstations ssh "${workstation}" \
    --project="${project}" --cluster="${cluster}" \
    --config="${config}" --region="${region}" \
    --port="${remote_port}" \
    --user="${user}"
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local action="$1"
  shift || true

  # Defaults
  local workstation="${WORKSTATION:-}"
  # If the next argument is NOT a flag, it is the workstation name
  if [[ -n "${1:-}" && "${1:-}" != --* ]]; then
    workstation="$1"
    shift
  fi

  local target_state="STATE_RUNNING"
  local project="${PROJECT:-}"
  local cluster="${CLUSTER:-}"
  local config="${CONFIG:-}"
  local region="${REGION:-}"
  local timeout="600"
  local local_port="2222"
  local remote_port="22"
  local user="user"
  local browser=""
  local manage_ssh_config="true"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target-state) target_state="$2"; shift 2 ;;
      --project)      project="$2"; shift 2 ;;
      --cluster)      cluster="$2"; shift 2 ;;
      --config)       config="$2"; shift 2 ;;
      --region)       region="$2"; shift 2 ;;
      --timeout)      timeout="$2"; shift 2 ;;
      --local-port)   local_port="$2"; shift 2 ;;
      --remote-port)  remote_port="$2"; shift 2 ;;
      --user)         user="$2"; shift 2 ;;
      --browser)
        if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
          browser="$2"
          shift 2
        else
          browser="google-chrome"
          shift 1
        fi
        ;;
      --no-ssh-config) manage_ssh_config="false"; shift ;;
      *) echo "Unknown flag: $1"; usage ;;
    esac
  done

  # Final assignment to ensure they are available in functions that don't take them as args
  # We export them so that gcloud and other tools pick them up as defaults if needed.
  export PROJECT="${project}"
  export CLUSTER="${cluster}"
  export CONFIG="${config}"
  export REGION="${region}"

  if [[ -z "${workstation}" ]]; then
    error "Workstation name is required."
  fi

  case "${action}" in
    start)
      start_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" "${browser}"
      ;;
    stop)
      stop_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}"
      ;;
    restart)
      stop_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}"
      start_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" "${browser}"
      ;;
    wait)
      wait_for_ws_state "${workstation}" "${target_state}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}"
      ;;
    ssh)
      ssh_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" "${remote_port}" "${user}"
      ;;
    tunnel)
      tunnel_ws "${workstation}" "${project}" "${cluster}" "${config}" "${region}" "${timeout}" "${local_port}" "${remote_port}" "${browser}" "${manage_ssh_config}" "${user}"
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
