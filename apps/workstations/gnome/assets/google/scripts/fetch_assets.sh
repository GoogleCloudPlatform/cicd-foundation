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

set -euo pipefail

download_and_validate() {
  local url="$1"
  local sha256="$2"
  local output_file="$3"

  echo "Downloading from ${url}..."
  curl ${CURL_OPTS} "${url}" -o "${output_file}"
  echo "${sha256} ${output_file}" | sha256sum -c -
}

# Extracts a tarball, creating the destination directory if it doesn't exist.
#
# $1: tarball_name
# $2: destination_dir
# $@: additional_tar_args (optional, variadic)
extract_tarball() {
  local tarball_name="$1"
  local destination_dir="$2"
  shift 2
  local additional_tar_args=("$@")

  mkdir -p "${destination_dir}"
  tar -xzf "${tarball_name}" -C "${destination_dir}" "${additional_tar_args[@]}"
  rm "${tarball_name}"
}

# Downloads a tarball, extracts a binary, installs it, and creates aliases.
#
# $1: url
# $2: sha256
# $3: tarball_name
# $4: file_to_extract
# $5: install_dir
# $6: install_name
# $@: aliases (optional, variadic)
install_binary_from_tarball() {
    local url="$1"
    local sha256="$2"
    local tarball_name="$3"
    local file_to_extract="$4"
    local install_dir="$5"
    local install_name="$6"
    shift 6 # Shift the first 6 arguments
    local aliases=("$@") # The rest are aliases

    download_and_validate "${url}" "${sha256}" "${tarball_name}"
    tar -xzf "${tarball_name}" "${file_to_extract}"
    mkdir -p "${install_dir}"
    mv "${file_to_extract}" "${install_dir}/${install_name}"

    for alias_name in "${aliases[@]}"; do
        ln -s "${install_name}" "${install_dir}/${alias_name}"
    done

    rm "${tarball_name}"
}

CRANE_TIMEOUT="${CRANE_TIMEOUT:-300}"
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-mirror.gcr.io}"

# This script fetches external assets required for the build.
# It is intended to be run during the 'fetcher' stage of the Dockerfile.

fetch_crane() {
  echo "Installing crane from ${CRANE_URL}..."
  install_binary_from_tarball "${CRANE_URL}" "${CRANE_SHA256}" "crane.tar.gz" "crane" "/usr/local/bin" "crane"
}

fetch_images() {
  echo "Fetching Guacamole images..."
  for image in ${GUACAMOLE_IMAGES}; do
    image_id="${CONTAINER_REGISTRY}/guacamole/${image}:${GUACAMOLE_VERSION}"
    echo "Pulling ${image_id}..."
    local i=1
    local pull_success=false
    
    while [[ "$i" -le "${RETRIES}" ]]; do
      if timeout "${CRANE_TIMEOUT}" crane pull "${image_id}" "/downloads/opt/images/${image}.tar"; then
        pull_success=true
        break
      fi
      
      echo "Retry $i/${RETRIES} for ${image_id} (crane pull failed or timed out)..."
      i=$((i + 1))
      sleep "${RETRY_WAIT}"
    done

    if [ "$pull_success" = false ]; then
      echo "ERROR: Failed to pull ${image_id} after ${RETRIES} attempts."
      exit 1
    fi
  done
}

fetch_extensions() {
  echo "Fetching Guacamole extensions..."
  for extension in ${GUACAMOLE_EXTENSIONS}; do
    extension_name="guacamole-${extension}-${GUACAMOLE_VERSION}"
    echo "Downloading ${extension_name}..."
    curl ${CURL_OPTS} "${GUACAMOLE_BASE_URL}/${extension_name}.tar.gz" |       tar -xz -C /downloads/etc/guacamole/extensions

    # Extract the jar file and clean up the archive
    mv "/downloads/etc/guacamole/extensions/${extension_name}"/*.jar /downloads/etc/guacamole/extensions/
    rm -rf "/downloads/etc/guacamole/extensions/${extension_name}"
  done
}

fetch_antigravity_assets() {
  echo "Fetching Antigravity assets (CLI v${ANTIGRAVITY_CLI_VERSION}, SDK v${ANTIGRAVITY_SDK_VERSION})..."
  
  # CLI
  local cli_url="https://github.com/google-antigravity/antigravity-cli/releases/download/${ANTIGRAVITY_CLI_VERSION}/agy_cli_linux_x64.tar.gz"
  install_binary_from_tarball "${cli_url}" "${ANTIGRAVITY_CLI_SHA256}" "antigravity_cli.tar.gz" "antigravity" "/downloads/usr/local/bin" "antigravity-cli" "agy"

  # SDK (Source as fallback)
  local sdk_url="https://github.com/google-antigravity/antigravity-sdk-python/archive/refs/tags/v${ANTIGRAVITY_SDK_VERSION}.tar.gz"
  download_and_validate "${sdk_url}" "${ANTIGRAVITY_SDK_SHA256}" "antigravity_sdk.tar.gz"
  extract_tarball "antigravity_sdk.tar.gz" "/downloads/opt/antigravity-sdk" "--strip-components=1"
}

fetch_adk() {
  echo "Fetching Agent Development Kit (ADK) v${ADK_VERSION}..."
  local adk_url="https://github.com/google/adk-python/archive/refs/tags/v${ADK_VERSION}.tar.gz"
  download_and_validate "${adk_url}" "${ADK_SHA256}" "google_adk.tar.gz"
  extract_tarball "google_adk.tar.gz" "/downloads/opt/google-adk" "--strip-components=1"
}

fetch_uv() {
  echo "Installing uv v${UV_VERSION}..."
  install_binary_from_tarball "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" "${UV_SHA256}" "uv.tar.gz" "uv-x86_64-unknown-linux-musl/uv" "/usr/local/bin" "uv"
}

main() {
  mkdir -p /downloads/opt/images /downloads/etc/guacamole/extensions
  fetch_crane
  fetch_images
  fetch_extensions
  fetch_antigravity_assets
  fetch_adk
  fetch_uv
  echo "Assets fetched successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
