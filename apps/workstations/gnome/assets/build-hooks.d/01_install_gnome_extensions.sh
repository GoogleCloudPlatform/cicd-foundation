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

# Installs GNOME Shell extensions from a space-separated list.
# Expected format: "ext1@domain:version1 ext2@domain:version2"
install_extensions() {
  local extensions="${GNOME_SHELL_EXTENSIONS:-}"

  if [[ -z "${extensions}" ]]; then
    echo "No GNOME extensions to install."
    return 0
  fi

  mkdir -p /usr/share/gnome-shell/extensions

  local ext_info
  for ext_info in ${extensions}; do
    local ext_id
    ext_id=$(echo "${ext_info}" | cut -d: -f1)
    local ext_version
    ext_version=$(echo "${ext_info}" | cut -d: -f2)

    # Construct download URL using the extension-data format which is more reliable for direct links
    # Format: https://extensions.gnome.org/extension-data/UUID_WITHOUT_AT.vVERSION.shell-extension.zip
    local ext_id_clean
    ext_id_clean=$(echo "${ext_id}" | sed "s/@//g")
    local download_url="https://extensions.gnome.org/extension-data/${ext_id_clean}.v${ext_version}.shell-extension.zip"

    echo "Downloading GNOME extension: ${ext_id} (version ${ext_version}) from ${download_url}"

    # Ensure the target directory exists before curl
    mkdir -p "/usr/share/gnome-shell/extensions/${ext_id}"

    # Download and unzip directly to the target location
    local tmp_zip
    tmp_zip=$(mktemp)
    # Source common.sh to get CURL_OPTS if available
    # shellcheck disable=SC1091
    [[ -f /google/scripts/common.sh ]] && . /google/scripts/common.sh
    local curl_cmd="curl ${CURL_OPTS:--fsSL --retry 3 --connect-timeout 10 --max-time 300}"

    if ! ${curl_cmd} -L "${download_url}" -o "${tmp_zip}"; then
      echo "Failed to download extension from ${download_url}. Trying fallback format..."
      # Fallback to official download-extension API if direct link fails
      local ext_id_encoded
      ext_id_encoded=$(echo "${ext_id}" | sed "s/@/%40/g")
      download_url="https://extensions.gnome.org/download-extension/${ext_id_encoded}.shell-extension.zip?version_tag=${ext_version}"
      echo "Trying fallback URL: ${download_url}"
      ${curl_cmd} -L "${download_url}" -o "${tmp_zip}"
    fi

    unzip -q -o "${tmp_zip}" -d "/usr/share/gnome-shell/extensions/${ext_id}/"
    rm -f "${tmp_zip}"

    # Patch just-perfection to FORCE hide screen sharing and recording indicators in GNOME 46
    if [[ "${ext_id}" == "just-perfection-desktop@just-perfection" ]]; then
      local patch_file="/usr/share/gnome-shell/extension-patches/${ext_id}/stylesheet-patch.css"
      if [[ -f "${patch_file}" ]]; then
        echo "Patching Just Perfection to forcefully hide screen sharing indicators using ${patch_file}..."
        cat "${patch_file}" >> "/usr/share/gnome-shell/extensions/${ext_id}/stylesheet.css"
      else
        echo "Warning: Patch file ${patch_file} not found. Skipping CSS patch."
      fi
    fi

    # If the extension has schemas, copy them to the system directory for overrides to work
    if [[ -d "/usr/share/gnome-shell/extensions/${ext_id}/schemas" ]]; then
      echo "Found schemas for ${ext_id}, compiling local schemas and copying to system schemas directory..."
      glib-compile-schemas "/usr/share/gnome-shell/extensions/${ext_id}/schemas" || true
      cp "/usr/share/gnome-shell/extensions/${ext_id}/schemas"/*.gschema.xml /usr/share/glib-2.0/schemas/ || true
    fi

    # Ensure correct permissions (some zips have restrictive permissions, and glib-compile-schemas creates files as root)
    chmod -R 755 "/usr/share/gnome-shell/extensions/${ext_id}/"
  done

  echo "Re-compiling glib schemas..."
  glib-compile-schemas /usr/share/glib-2.0/schemas
}

main() {
  install_extensions
}

main "$@"
