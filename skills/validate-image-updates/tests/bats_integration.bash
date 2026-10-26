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

# bats_integration.bash: Workstation-specific integration test helpers.

setup_env() {
  export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-YOUR_PROJECT_ID}"
  export CWS_CLUSTER="${CWS_CLUSTER:-YOUR_CLUSTER_NAME}"
  export CWS_CONFIG="${CWS_CONFIG:-YOUR_CONFIG_NAME}"
  export CWS_REGION="${CWS_REGION:-YOUR_REGION}"
  export CWS_NAME="${CWS_NAME:-YOUR_WORKSTATION_NAME}"
  export EXTRA_BINARIES="${EXTRA_BINARIES:-}"

  if [[ "${GOOGLE_CLOUD_PROJECT}" == "YOUR_PROJECT_ID" ]]; then
    skip "Missing integration test configuration. Please set variables or provide a .env file."
  fi

  # Check if workstation is running
  local state
  state=$(gcloud workstations describe \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --cluster="${CWS_CLUSTER}" \
    --config="${CWS_CONFIG}" \
    --region="${CWS_REGION}" \
    "${CWS_NAME}" \
    --format="value(state)" 2>/dev/null || echo "UNKNOWN")

  if [[ "${state}" != "STATE_RUNNING" ]]; then
    skip "Workstation ${CWS_NAME} is not running (Current state: ${state}). Skipping integration tests."
  fi
}

run_ssh() {
  local cmd="$1"
  local output

  output=$(gcloud workstations ssh \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --cluster="${CWS_CLUSTER}" \
    --config="${CWS_CONFIG}" \
    --region="${CWS_REGION}" \
    "${CWS_NAME}" \
    --command="${cmd} && echo _CWS_CMD_SUCCESS_" 2>&1)

  echo "$output"
  if [[ "$output" == *_CWS_CMD_SUCCESS_* ]]; then
    return 0
  else
    return 1
  fi
}

# shellcheck disable=SC2154
assert_app_autostarted() {
  local desktop_file="${1}.desktop"
  run run_ssh "ls -l /etc/xdg/autostart/${desktop_file}"
  [ "$status" -eq 0 ]
}

# shellcheck disable=SC2154
assert_app_pinned() {
  local desktop_file="${1}.desktop"
  run run_ssh "grep -q '${desktop_file}' /usr/share/glib-2.0/schemas/99-workstation-favorites.gschema.override"
  [ "$status" -eq 0 ]
}
