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

install_antigravity() {
  ANTIGRAVITY_CLI_VERSION="${ANTIGRAVITY_CLI_VERSION:-1.0.7}"
  ANTIGRAVITY_SDK_VERSION="${ANTIGRAVITY_SDK_VERSION:-0.1.3}"

  if [[ "${INSTALL_ANTIGRAVITY_CLI:-true}" == "true" ]]; then
    echo "Installing Antigravity CLI..."
    curl -fsSL "https://github.com/google-antigravity/antigravity-cli/releases/download/${ANTIGRAVITY_CLI_VERSION}/agy_cli_linux_x64.tar.gz" -o agy.tar.gz
    tar -xzf agy.tar.gz
    mv antigravity /usr/local/bin/antigravity-cli
    ln -s antigravity-cli /usr/local/bin/agy
    chmod +x /usr/local/bin/antigravity-cli
    rm agy.tar.gz
  fi

  if [[ "${INSTALL_ANTIGRAVITY_SDK:-true}" == "true" ]]; then
    echo "Installing Antigravity SDK..."
    curl -fsSL "https://github.com/google-antigravity/antigravity-sdk-python/archive/refs/tags/v${ANTIGRAVITY_SDK_VERSION}.tar.gz" -o agy_sdk.tar.gz
    mkdir -p /opt/antigravity-sdk
    tar -xzf agy_sdk.tar.gz -C /opt/antigravity-sdk --strip-components=1
    rm agy_sdk.tar.gz
  fi
}

main() {
  install_antigravity
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
