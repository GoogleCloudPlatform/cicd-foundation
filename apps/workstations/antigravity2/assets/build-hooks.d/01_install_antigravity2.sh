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

# shellcheck source=apps/workstations/base/assets/google/scripts/build/install_functions.sh
source /google/scripts/build/install_functions.sh

# Define variables
# shellcheck disable=SC2269
ANTIGRAVITY2_VERSION="${ANTIGRAVITY2_VERSION}"
# shellcheck disable=SC2269
ANTIGRAVITY2_SHA256="${ANTIGRAVITY2_SHA256}"
# shellcheck disable=SC2269
CURL_OPTS="${CURL_OPTS}"

# Construct the download URL
DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${ANTIGRAVITY2_VERSION}/linux-x64/Antigravity.tar.gz"
TARBALL_NAME="Antigravity.tar.gz"
EXTRACT_DIR="/opt"
BINARY_PATH="/opt/Antigravity-x64/antigravity"
INSTALL_NAME="antigravity-2.0"
ALIAS_NAME="antigravity"

download_and_validate "${DOWNLOAD_URL}" "${ANTIGRAVITY2_SHA256}" "${TARBALL_NAME}"

mkdir -p "${EXTRACT_DIR}"
tar -xzf "${TARBALL_NAME}" -C "${EXTRACT_DIR}"
rm "${TARBALL_NAME}"
