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

# This script manages a "hard silence" firewall for the workstation.
# It prevents any external connections until the environment is ready.

# We use nftables as it is the modern standard and available in the image.
setup_table() {
  nft add table inet workstation_mgmt
  nft add chain inet workstation_mgmt input { type filter hook input priority filter \; policy accept \; }
}

block_traffic() {
  # shellcheck source=/dev/null
  source /google/scripts/common.sh
  log "Blocking all external traffic (except loopback)..."
  setup_table
  # 1. Allow loopback traffic
  nft add rule inet workstation_mgmt input iifname "lo" accept
  # 2. Drop all other input traffic
  nft add rule inet workstation_mgmt input drop
}

permit_traffic() {
  # shellcheck source=/dev/null
  source /google/scripts/common.sh
  log_event IMAGE_READY "Workstation is reachable and traffic is permitted"
  nft delete table inet workstation_mgmt 2>/dev/null || true
}

main() {
  local action="${1:-block}"

  case "${action}" in
    block)
      block_traffic
      ;;
    permit)
      permit_traffic
      ;;
    *)
      echo "Usage: $0 [block|permit]"
      exit 1
      ;;
  esac
}

main "$@"
