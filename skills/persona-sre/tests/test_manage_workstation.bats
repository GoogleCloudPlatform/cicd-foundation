#!/usr/bin/env bats

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

load test_helper.bash

setup() {
  # Mock gcloud (exported via export -f for child script processes)
  # shellcheck disable=SC2329
  gcloud() {
    echo "MOCK_GCLOUD_ARGS: $*" >&2
    case "$*" in
      *"workstations describe"*value\(state\)*)
        # Return RUNNING if it's the second call or if we want to simulate already running
        echo "STATE_RUNNING"
        ;;
      *"workstations describe"*value\(host\)*)
        echo "mock-cws-host.workstations.google"
        ;;
      *)
        # Default to success for other commands (start/stop)
        return 0
        ;;
    esac
  }
  export -f gcloud

  # Mock browser (exported via export -f for child script processes)
  # shellcheck disable=SC2329
  google-chrome() {
    echo "MOCK_BROWSER: $*"
  }
  export -f google-chrome

  # Use a temporary home for SSH config tests and isolate optional CWS_* env vars
  unset BROWSER CWS_LOCAL_PORT CWS_NAME CWS_CLUSTER CWS_CONFIG CWS_REGION GOOGLE_CLOUD_PROJECT
  export HOME="${BATS_FILE_TMPDIR}/mock-home"
  mkdir -p "${HOME}/.ssh"
}

@test "manage_workstation.sh start ensures workstation is running" {
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" start mock-cws --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1
  [ "$status" -eq 0 ]
  # Since it's already running in the mock, it should just log it
  [[ "$output" =~ "Workstation mock-cws is already running" ]]
}

@test "manage_workstation.sh correctly uses CWS_NAME from env when first arg is a flag" {
  export CWS_NAME="env-cws"
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" start --browser --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Workstation env-cws is already running" ]]
}

@test "manage_workstation.sh start with browser opens URL" {
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" start mock-cws --browser --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1
  [ "$status" -eq 0 ]
  [[ "$output" == *'Opening https://mock-cws-host.workstations.google'* ]]
  [[ "$output" == *'MOCK_BROWSER: https://mock-cws-host.workstations.google'* ]]
}

@test "manage_workstation.sh stop stops the workstation" {
  # Change mock for stop
  gcloud() {
    if [[ "$*" == *"workstations describe"* && "$*" == *"value(state)"* ]]; then
      echo "STATE_STOPPED"
    else
      echo "MOCK_GCLOUD: $*"
    fi
  }
  export -f gcloud

  run bash "${SCRIPTS_DIR}/manage_workstation.sh" stop mock-cws --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Stopping Workstation: mock-cws" ]]
}

@test "manage_workstation.sh wait polls until target state" {
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" wait mock-cws --target-state STATE_RUNNING --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1
  [ "$status" -eq 0 ]
  [[ "$output" =~ "reached STATE_RUNNING" ]]
}

@test "manage_workstation.sh correctly uses CWS_REGION from env" {
  export CWS_REGION="env-region"
  # We test that the script correctly defaults its region variable to the env var
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" wait mock-cws --target-state STATE_RUNNING --project mock-proj --cluster mock-cluster --config mock-config --timeout 1
  [ "$status" -eq 0 ]
}

@test "manage_workstation.sh tunnel establishes SSH tunnel and cws SSH config" {
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" tunnel mock-cws --project mock-proj --cluster mock-cluster --config mock-config --region mock-region --timeout 1 --local-port 2222
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Starting SSH tunnel on local port 2222" ]]
  # Accept either new addition or already exists
  [[ "$output" =~ "Added 'cws' entry to SSH config" || "$output" =~ "SSH config already contains 'cws' entry" ]]
  # Check if gcloud was called with correct command (mocked to stderr)
  [[ "$output" =~ "start-tcp-tunnel" ]]
  [ -f "${HOME}/.ssh/config" ]
  grep -q "Host cws" "${HOME}/.ssh/config"
  grep -q "Port 2222" "${HOME}/.ssh/config"
}

@test "manage_workstation.sh status outputs the workstation state" {
  run bash "${SCRIPTS_DIR}/manage_workstation.sh" status mock-cws --project mock-proj --cluster mock-cluster --config mock-config --region mock-region
  [ "$status" -eq 0 ]
  [[ "$output" == *"STATE_RUNNING"* ]]
}

@test "manage_workstation.sh runs standalone without ../../common.sh using CWS_* env vars" {
  local standalone_dir="${BATS_TEST_TMPDIR}/standalone"
  mkdir -p "${standalone_dir}"
  cp "${SCRIPTS_DIR}/manage_workstation.sh" "${standalone_dir}/manage_workstation.sh"

  export CWS_NAME="standalone-cws"
  export GOOGLE_CLOUD_PROJECT="standalone-proj"
  export CWS_CLUSTER="standalone-cluster"
  export CWS_CONFIG="standalone-config"
  export CWS_REGION="standalone-region"
  export CWS_LOCAL_PORT="2223"

  run bash "${standalone_dir}/manage_workstation.sh" tunnel --browser
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Workstation standalone-cws is already running" ]]
  [[ "$output" =~ "Starting SSH tunnel on local port 2223" ]]
  grep -q "Host cws" "${HOME}/.ssh/config"
  grep -q "Port 2223" "${HOME}/.ssh/config"
}
