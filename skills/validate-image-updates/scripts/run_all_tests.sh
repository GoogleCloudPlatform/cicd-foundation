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

# This script is the primary entrypoint for ALL tests.
# It orchestrates both local checks and cloud-based integration tests.

main() {
  # Ensure we call sibling scripts relative to this script's location
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # 1. Run all Local Checks (Linter, Unit Tests, Frontend)
  "${script_dir}/run_local_tests.sh"

  # 2. Run Integration Tests
  "${script_dir}/run_integration_tests.sh" "$@"
}

main "$@"
