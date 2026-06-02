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

# This script dumps journalctl logs to stdout for Cloud Logging.

set -euo pipefail

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

main() {
  # dump logs to stdout for cloud logging in the background
  {
    until journalctl -n0 >/dev/null 2>&1; do
      log "waiting for journalctl"
      sleep 1
    done
    log "following journalctl"
    journalctl -f
  } &
}

main "$@"
