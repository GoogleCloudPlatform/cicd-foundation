#!/bin/sh

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

set -e

PREFLIGHT_WEB_REPO="$1"
PREFLIGHT_WEB_DIR="$2"

BUILD_DIST_DIR="/build/web/dist"
mkdir -p "${BUILD_DIST_DIR}"

perform_build() {
  source_path="$1"
  echo "Building SPA from ${source_path}..."
  cd "${source_path}"
  npm install --silent && npm run build
  cp -pR dist/. "${BUILD_DIST_DIR}/"
}

if [ -n "${PREFLIGHT_WEB_REPO}" ]; then
  echo "Cloning ${PREFLIGHT_WEB_REPO}..."
  git clone "${PREFLIGHT_WEB_REPO}" repo
  perform_build "repo/${PREFLIGHT_WEB_DIR:-.}"
elif [ -d "/build/web/source" ] && [ -f "/build/web/source/package.json" ]; then
  perform_build "/build/web/source"
else
  echo "No source provided. Skipping SPA build."
fi
