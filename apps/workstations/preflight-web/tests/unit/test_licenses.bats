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
  # BATS_TEST_FILENAME points to the absolute path of the current test file
  TEST_FILE_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  ASSETS_ROOT="$(cd "${TEST_FILE_DIR}/../../public" && pwd)"
  SBOM_FILE="${ASSETS_ROOT}/sbom.json"
  VALIDATOR="${TEST_FILE_DIR}/lib/sbom_validator.py"
}

@test "SBOM manifest is valid and has metadata" {
  run "${VALIDATOR}" manifest "${SBOM_FILE}"
  [ "$status" -eq 0 ]
}

@test "All license assets exist and match signatures" {
  run "${VALIDATOR}" assets "${SBOM_FILE}" "${ASSETS_ROOT}"
  [ "$status" -eq 0 ]
}
