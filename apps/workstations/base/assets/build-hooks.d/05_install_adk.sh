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

install_adk() {
  local enabled="${INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON:-true}"
  ADK_VERSION="${ADK_VERSION:-2.3.0}"

  if [[ "${enabled}" == "true" ]]; then
    echo "Installing Agent Development Kit (Python)..."
    curl -fsSL "https://github.com/google/adk-python/archive/refs/tags/v${ADK_VERSION}.tar.gz" -o adk.tar.gz
    mkdir -p /opt/google-adk
    tar -xzf adk.tar.gz -C /opt/google-adk --strip-components=1
    rm adk.tar.gz
  fi
}

main() {
  install_adk
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
