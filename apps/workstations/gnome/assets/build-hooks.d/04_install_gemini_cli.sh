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

install_gemini_cli() {
  # Optional: Install Gemini CLI
  if [[ "${INSTALL_GEMINI_CLI:-true}" == "true" ]]; then
    echo "Installing Gemini CLI..."
    npm install -g @google/gemini-cli
    npm cache clean --force
  else
    echo "Gemini CLI installation skipped."
  fi
}

main() {
  install_gemini_cli
}

main "$@"
