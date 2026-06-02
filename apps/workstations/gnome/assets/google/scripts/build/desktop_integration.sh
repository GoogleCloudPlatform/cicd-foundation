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

# This utility script centralizes the orchestration of desktop integration.
# It allows child layers to register applications for autostart and dock pinning
# via standard .desktop metadata.

# Registers an application with custom metadata keys.
# Usage: desktop_register_app <desktop_file_path> [priority] [autostart=true|false] [favorite=true|false]
desktop_register_app() {
  local desktop_file="${1}"
  local priority="${2:-50}"
  local autostart="${3:-true}"
  local favorite="${4:-true}"

  if [[ ! -f "${desktop_file}" ]]; then
    echo "Error: .desktop file not found: ${desktop_file}" >&2
    return 1
  fi

  echo "Registering: $(basename "${desktop_file}") (Priority: ${priority}, Autostart: ${autostart}, Favorite: ${favorite})"

  # Ensure [Desktop Entry] section exists (it should)
  if ! grep -q "\[Desktop Entry\]" "${desktop_file}"; then
    echo "Error: Invalid .desktop file: ${desktop_file}" >&2
    return 1
  fi

  # Remove existing keys if they exist to avoid duplicates
  sed -i "/^X-Workstation-Favorite-Priority=/d" "${desktop_file}"
  sed -i "/^X-Workstation-Favorite=/d" "${desktop_file}"
  sed -i "/^X-GNOME-Autostart-enabled=/d" "${desktop_file}"

  # Inject metadata keys
  sed -i "/\[Desktop Entry\]/a X-Workstation-Favorite-Priority=${priority}" "${desktop_file}"
  sed -i "/\[Desktop Entry\]/a X-Workstation-Favorite=${favorite}" "${desktop_file}"
  sed -i "/\[Desktop Entry\]/a X-GNOME-Autostart-enabled=${autostart}" "${desktop_file}"

  chmod 644 "${desktop_file}"
}

# Scans all .desktop files and applies system-wide integration.
desktop_apply_integration() {
  local apps_dir="/usr/share/applications"
  local autostart_dir="/etc/xdg/autostart"
  local schema_dir="/usr/share/glib-2.0/schemas"
  local override_file="${schema_dir}/99-workstation-favorites.gschema.override"

  echo "Applying centralized desktop integration..."

  # 0. Explicit Primary Application
  # Child layers can set this ENV to declare the primary application for the image.
  local default_app="${WORKSTATION_DEFAULT_APP:-}"
  if [[ -n "${default_app}" ]] && [[ -f "${apps_dir}/${default_app}.desktop" ]]; then
    echo "  -> Primary application specified: ${default_app}"
    desktop_register_app "${apps_dir}/${default_app}.desktop" 30 true true
  fi

  # 1. Autodiscovery of user applications
  # We look for apps in relevant categories that haven't been explicitly registered.
  echo "Scanning for additional applications to pin and autostart..."
  local priority=40
  # Find candidates (excluding those already registered)
  local candidates
  candidates=$(grep -lE "Categories=.*(Development|IDE|TerminalEmulator|TextEditor)" "${apps_dir}"/*.desktop 2>/dev/null || true)

  for desktop_file in ${candidates}; do
    if ! grep -q "^X-Workstation-Favorite=" "${desktop_file}"; then
      # Pin discovered dev tools, but do not autostart them by default
      local autostart="false"
      if grep -qE "Categories=.*(IDE|Development)" "${desktop_file}"; then
        echo "  -> Autodiscovered IDE/Dev tool (pinned): $(basename "${desktop_file}")"
      fi

      desktop_register_app "${desktop_file}" "${priority}" "${autostart}" true
      priority=$((priority + 1))
    fi
  done

  # 2. Autostart Integration
  mkdir -p "${autostart_dir}"
  local autostart_apps
  autostart_apps=$(grep -l "X-GNOME-Autostart-enabled=true" "${apps_dir}"/*.desktop 2>/dev/null || true)
  for desktop_file in ${autostart_apps}; do
    local filename
    filename=$(basename "${desktop_file}")
    echo "  -> Enabling autostart: ${filename}"
    ln -sf "${desktop_file}" "${autostart_dir}/${filename}"
  done

  # 3. Dock Pinning (Favorite Apps)
  # We find all favorites, sort them by priority, and build the GSettings array.
  local tmp_favs
  tmp_favs=$(mktemp)

  local favorite_apps
  favorite_apps=$(grep -l "X-Workstation-Favorite=true" "${apps_dir}"/*.desktop 2>/dev/null || true)
  for desktop_file in ${favorite_apps}; do
    local filename
    filename=$(basename "${desktop_file}")
    local priority
    priority=$(grep "^X-Workstation-Favorite-Priority=" "${desktop_file}" | cut -d'=' -f2 || echo "50")
    echo "${priority} ${filename}" >> "${tmp_favs}"
  done

  # Sort by priority (numeric) and then filename
  if [[ -s "${tmp_favs}" ]]; then
    echo "Generating dock favorites override..."
    local apps_list
    apps_list=$(sort -n -k1 "${tmp_favs}" | awk '{print $2}' | xargs | sed "s/ /', '/g")

    cat > "${override_file}" <<EOF
[org.gnome.shell]
favorite-apps=['${apps_list}']

[org.gnome.shell:ubuntu]
favorite-apps=['${apps_list}']
EOF
    echo "  -> Favorites: [${apps_list}]"
  fi
  rm -f "${tmp_favs}"

  # 3. System Maintenance
  echo "Refreshing system databases..."
  if [[ -d "${schema_dir}" ]]; then
    glib-compile-schemas "${schema_dir}"
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${apps_dir}"
  fi
}

# If executed directly, apply integration
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  desktop_apply_integration
fi
