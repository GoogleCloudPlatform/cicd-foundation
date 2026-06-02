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

load ../test_helper.bash

setup() {
  export MONITOR_TRIGGER_SLEEP=0.1
  export MONITOR_POLL_INTERVAL=0.1
  export MONITOR_TRIGGER_TIMEOUT=1
  export WORKSTATION="mock-ws"
  export CLUSTER="mock-cluster"

  # Use BATS's managed temporary directory for the mock script
  export MANAGE_WS_SCRIPT="${BATS_FILE_TMPDIR}/manage_workstation.sh"

  cat <<EOF > "${MANAGE_WS_SCRIPT}"
#!/bin/bash
echo "WS_ACTION: \$1"
EOF
  chmod +x "${MANAGE_WS_SCRIPT}"

  # Mock gcloud
  gcloud() {
    case "$*" in
      *"builds list"*) echo "mock-build-id-123" ;;
      *"builds describe"*) echo "SUCCESS" ;;
      *"workstations describe"*value\(state\)*) echo "STATE_RUNNING" ;;
      *) echo "mock-output" ;;
    esac
  }
  export -f gcloud
}

@test "monitor_build.sh runs successfully when build succeeds" {
  export -f gcloud
  run bash ./skills/persona-sre/scripts/monitor_build.sh --region "mock-region" --project "mock-project"
  echo "DEBUG OUTPUT: $output"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "mock-build-id-123" ]]
  [[ "$output" =~ "Build successful" ]]
  [[ "$output" =~ "Workstation" ]] && [[ "$output" =~ "running" ]]
}

@test "monitor_build.sh fails when build fails" {
  gcloud() {
    case "$*" in
      *"builds list"*) echo "mock-build-id-fail" ;;
      *"builds describe"*) echo "FAILURE" ;;
      *) echo "mock-output" ;;
    esac
  }
  export -f gcloud

  run bash ./skills/persona-sre/scripts/monitor_build.sh --region "mock-region" --project "mock-project"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "mock-build-id-fail" ]]
  [[ "$output" =~ "FAILURE" ]]
}
