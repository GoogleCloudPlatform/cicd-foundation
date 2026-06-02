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

# This hook triggers the centralized workstation configuration.

main() {
  local apps_dir="/usr/share/applications"

  echo "Registering base applications..."

  # Explicitly register core apps with high priority
  # shellcheck source=/dev/null
  source /google/scripts/build/desktop_integration.sh

  if [[ -f "${apps_dir}/google-chrome.desktop" ]]; then
    desktop_register_app "${apps_dir}/google-chrome.desktop" 10 false true
  fi

  if [[ -f "${apps_dir}/org.gnome.Nautilus.desktop" ]]; then
    desktop_register_app "${apps_dir}/org.gnome.Nautilus.desktop" 20 false true
  fi

  if [[ -f "${apps_dir}/org.gnome.Terminal.desktop" ]]; then
    desktop_register_app "${apps_dir}/org.gnome.Terminal.desktop" 30 false true
  fi
}

main "$@"
