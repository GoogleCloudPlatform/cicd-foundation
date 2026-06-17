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

CRANE_TIMEOUT="${CRANE_TIMEOUT:-300}"
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-mirror.gcr.io}"

# This script fetches external assets required for the build.
# It is intended to be run during the 'fetcher' stage of the Dockerfile.

fetch_crane() {
  echo "Installing crane from ${CRANE_URL}..."
  curl ${CURL_OPTS} "${CRANE_URL}" | tar -xz crane
  mv crane /usr/local/bin/
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
  mkdir -p /downloads/usr/local/bin
  local cli_url="https://github.com/google-antigravity/antigravity-cli/releases/download/${ANTIGRAVITY_CLI_VERSION}/agy_cli_linux_x64.tar.gz"
  echo "Downloading Antigravity CLI from ${cli_url}..."
  curl ${CURL_OPTS} "${cli_url}" | tar -xz -C /downloads/usr/local/bin agy

  # SDK (Source as fallback)
  mkdir -p /downloads/opt/antigravity-sdk
  local sdk_url="https://github.com/google-antigravity/antigravity-sdk-python/archive/refs/tags/v${ANTIGRAVITY_SDK_VERSION}.tar.gz"
  echo "Downloading Antigravity SDK source from ${sdk_url}..."
  curl ${CURL_OPTS} "${sdk_url}" | tar -xz -C /downloads/opt/antigravity-sdk --strip-components=1
}

main() {
  mkdir -p /downloads/opt/images /downloads/etc/guacamole/extensions
  fetch_crane
  fetch_images
  fetch_extensions
  fetch_antigravity_assets
  echo "Assets fetched successfully."
}

main "$@"
