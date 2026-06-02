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

set -euo pipefail

install_adk() {
  local enabled="${INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON:-false}"

  if [[ "${enabled}" == "true" ]]; then
    echo "Installing Agent Development Kit (Python)..."

    # Ensure pipx is ready
    export PIPX_BIN_DIR=/usr/local/bin
    export PIPX_HOME=/opt/pipx

    # Install google-adk via pipx
    pipx install google-adk

    echo "Agent Development Kit installed successfully."
  else
    echo "Agent Development Kit installation skipped."
  fi
}
main() {
  install_adk
}

main "$@"
