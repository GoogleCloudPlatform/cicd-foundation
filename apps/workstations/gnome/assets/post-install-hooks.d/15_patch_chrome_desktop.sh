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

DESKTOP_FILE="/usr/share/applications/google-chrome.desktop"

if [[ -f "${DESKTOP_FILE}" ]]; then
  echo "Patching ${DESKTOP_FILE} to use the Chrome wrapper..."
  # Point all Exec lines to the wrapper script, which handles GPU-conditional flags
  sed -i 's|^Exec=/usr/bin/google-chrome-stable|Exec=/usr/local/bin/google-chrome-stable|g' "${DESKTOP_FILE}"

  # Register as a high-priority favorite (but do not autostart)
  # Priority 20 ensures it appears before IDEs (30)
  # shellcheck source=/dev/null
  source /google/scripts/build/desktop_integration.sh
  desktop_register_app "${DESKTOP_FILE}" 20 false true

  echo "Successfully patched Google Chrome desktop entry."
else
  echo "Warning: ${DESKTOP_FILE} not found. Skipping patch."
fi
