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

# shellcheck source=/dev/null
source /google/scripts/common.sh

DESKTOP_FILE="/usr/share/applications/antigravity.desktop"

if [[ -f "${DESKTOP_FILE}" ]]; then
  log "Patching ${DESKTOP_FILE} to use the Antigravity wrapper..."
  # Point all Exec lines to the wrapper script, which handles GPU-conditional flags
  sed -i 's|^Exec=/usr/share/antigravity/antigravity|Exec=/usr/local/bin/antigravity|g' "${DESKTOP_FILE}"

  # Register as a top-priority favorite and enable autostart
  # Priority 10 ensures it appears first in the dock
  # shellcheck source=/dev/null
  source /google/scripts/build/desktop_integration.sh
  desktop_register_app "${DESKTOP_FILE}" 10 true true

  log_event BUILD_HOOK_COMPLETED "Successfully patched Antigravity desktop entry" HOOK=patch-antigravity
else
  warn "${DESKTOP_FILE} not found. Skipping patch."
fi
