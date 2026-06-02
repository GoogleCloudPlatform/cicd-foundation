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

DESKTOP_FILE="/usr/share/applications/asfp-canary.desktop"

patch_asfp_desktop() {
  if [[ -f "${DESKTOP_FILE}" ]]; then
    log "Patching ${DESKTOP_FILE} for stability..."

    # Force the ASfP wrapper script for stability and native Wayland backend.
    # The wrapper handles the polling loop for the Wayland socket to avoid race conditions.
    if [[ -f "/usr/local/bin/asfp-studio" ]]; then
      chmod 755 "/usr/local/bin/asfp-studio"
      sed -i 's|^Exec=.*|Exec=/usr/local/bin/asfp-studio|' "${DESKTOP_FILE}"
    fi

    # Ensure the WM class matches the IDE for correct task grouping and dock mapping
    if ! grep -q "StartupWMClass=jetbrains-studio" "${DESKTOP_FILE}"; then
      sed -i 's|^StartupWMClass=.*|StartupWMClass=jetbrains-studio|' "${DESKTOP_FILE}"
    fi

    log_event BUILD_HOOK_COMPLETED "Successfully patched ASfP desktop entry"
  else
    warn "${DESKTOP_FILE} not found. ASfP package might not be installed correctly."
  fi
}

main() {
  patch_asfp_desktop
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
