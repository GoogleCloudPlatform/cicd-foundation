#!/usr/bin/env bats

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

setup() {
  TEST_FILE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  WEB_DIR="$(cd "${TEST_FILE_DIR}/../.." && pwd)"

  # Ensure dependencies and the dist folder exist
  if [[ ! -d "${WEB_DIR}/node_modules" ]]; then
    echo "node_modules not found. Running npm install..."
    (cd "${WEB_DIR}" && npm install)
  fi

  if [[ ! -d "${WEB_DIR}/dist" ]]; then
    echo "dist folder not found. Running build..."
    (cd "${WEB_DIR}" && npm run build)
  fi
}

@test "Global functions are not tree-shaken by Vite" {
  local bundle_file="${WEB_DIR}/dist/startup.js"

  # Assert the compiled bundle exists
  [ -f "${bundle_file}" ]

  # Assert that the global assignments survived minification
  run grep -E 'window\.openModal\s*=' "${bundle_file}"
  [ "$status" -eq 0 ]

  run grep -E 'window\.closeModal\s*=' "${bundle_file}"
  [ "$status" -eq 0 ]
}
