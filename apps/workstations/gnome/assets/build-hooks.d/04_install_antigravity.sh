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

install_antigravity() {
  # 1. Install Antigravity CLI
  if [[ "${INSTALL_ANTIGRAVITY_CLI:-true}" == "true" ]]; then
    echo "Configuring Antigravity CLI..."
    chmod +x /usr/local/bin/agy
    agy --version
  else
    echo "Antigravity CLI installation skipped."
  fi

  # 2. Install Antigravity SDK
  if [[ "${INSTALL_ANTIGRAVITY_SDK:-true}" == "true" ]]; then
    echo "Installing Antigravity SDK (v${ANTIGRAVITY_SDK_VERSION})..."

    # Ensure pipx is ready (environment variables should be inherited from Dockerfile/configure_workstation.sh)
    export PIPX_BIN_DIR=/usr/local/bin
    export PIPX_HOME=/opt/pipx

    if pipx install "antigravity-sdk-python==${ANTIGRAVITY_SDK_VERSION}"; then
      echo "Antigravity SDK installed successfully via pipx."
    else
      echo "Failed to install Antigravity SDK via pipx. Falling back to local source..."
      if [[ -d "/opt/antigravity-sdk" ]]; then
        pipx install /opt/antigravity-sdk
        echo "Antigravity SDK installed successfully from local source."
      else
        echo "ERROR: Local Antigravity SDK source not found."
        exit 1
      fi
    fi
  else
    echo "Antigravity SDK installation skipped."
  fi
}

main() {
  install_antigravity
}

main "$@"
