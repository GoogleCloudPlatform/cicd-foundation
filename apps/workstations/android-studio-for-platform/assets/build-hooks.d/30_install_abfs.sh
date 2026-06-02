#!/bin/bash

# Copyright 2024-2026 Google LLC
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

# Sourced logic (from preflight or local)
# shellcheck disable=SC1091
source "/google/scripts/common.sh"

configure_abfs() {
  local install_abfs_client="${INSTALL_ABFS_CLIENT:-false}"
  local abfs_list="/etc/apt/sources.list.d/abfs.list"

  if [[ "${install_abfs_client}" != "true" ]]; then
    echo "INSTALL_ABFS_CLIENT is false. Removing ABFS repository configuration."
    rm -f "${abfs_list}"
  else
    echo "ABFS client installation enabled. Repository configuration retained."
  fi
}

main() {
  configure_abfs
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
