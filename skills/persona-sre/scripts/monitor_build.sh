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
  echo "Usage: $0 [BUILD_ID] [flags]"
  echo ""
  echo "Arguments:"
  echo "  [BUILD_ID]     ID of the Cloud Build to monitor."
  echo ""
  echo "Flags:"
  echo "  --latest       Monitor the absolute latest build in the region."
  echo "  --project      GCP Project ID."
  echo "  --region       GCP Region."
  echo "  --lookback     Lookback minutes for latest build search (default: 10)."
  echo "  --interval     Polling interval in seconds (default: 30)."
  exit 1
}

# Helper to manage workstation lifecycle
manage_ws() {
  local action="$1"
  local project="${2:-${PROJECT:-}}"

  if [[ -z "${WORKSTATION:-}" || -z "${CLUSTER:-}" ]]; then
    return 0
  fi

  "${SCRIPT_DIR}/manage_workstation.sh" "${action}" "${WORKSTATION}" \
    --project "${project}" \
    --cluster "${CLUSTER}" \
    --config "${CONFIG:-}" \
    --region "${REGION:-}"
}

main() {
  local build_id=""
  # If the next argument is NOT a flag, it is the build_id
  if [[ -n "${1:-}" && "${1:-}" != --* ]]; then
    build_id="$1"
    shift
  fi

  # Defaults from environment or common.sh
  local region="${BUILD_REGION:-${REGION:-}}"
  local project="${PROJECT:-}"
  local use_latest="${MONITOR_USE_LATEST:-false}"
  local lookback="${MONITOR_LOOKBACK_MINUTES:-10}"
  local interval="${MONITOR_POLL_INTERVAL:-30}"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --latest)   use_latest="true"; shift ;;
      --project)  project="$2"; shift 2 ;;
      --region)   region="$2"; shift 2 ;;
      --lookback) lookback="$2"; shift 2 ;;
      --interval) interval="$2"; shift 2 ;;
      --help)     usage ;;
      *) echo "Unknown flag: $1"; usage ;;
    esac
  done

  if [[ -z "${project}" ]]; then
    error "PROJECT must be set via .env or --project."
  fi

  if [[ -z "${region}" ]]; then
    error "Region must be set via .env (REGION/BUILD_REGION) or --region."
  fi

  if [[ -z "${build_id}" ]]; then
    if [[ "${use_latest}" == "true" ]]; then
      log "Fetching the latest build ID..."
      build_id=$(gcloud builds list --region="${region}" --project="${project}" --limit=1 --format="value(id)")
    else
      log "Fetching the latest build ID triggered in the last ${lookback} minutes..."
      build_id=$(gcloud builds list --region="${region}" --project="${project}" --filter="createTime > -PT${lookback}M" --limit=1 --format="value(id)")
    fi
  fi

  if [[ -z "${build_id}" ]]; then
    error "No build ID found to monitor."
  fi

  log "--- Monitoring Cloud Build: ${build_id} (Region: ${region}) ---"

  local status
  until status=$(gcloud builds describe "${build_id}" --project="${project}" --region="${region}" --format="value(status)") && \
        [[ "${status}" =~ ^(SUCCESS|FAILURE|CANCELLED|TIMEOUT)$ ]]; do
    log "Build status: ${status:-PENDING}..."
    sleep "${interval}"
  done

  if [[ "${status}" == "SUCCESS" ]]; then
    log "✅ Build successful! Triggering workstation start..."
    manage_ws "start" "${project}"
  else
    error "Build failed with status: ${status}. Check logs: gcloud builds log ${build_id} --project=${project} --region=${region}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
