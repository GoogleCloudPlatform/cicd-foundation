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

load test_helper.bash

@test "Verify directory structure: apps/ exists" {
  [ -d "${REPO_ROOT}/apps" ]
}

@test "Verify directory structure: apps/workstations exists" {
  [ -d "${REPO_ROOT}/apps/workstations" ]
}

@test "Every image in apps/workstations/ must have a Dockerfile" {
  # Find all directories containing a Dockerfile under apps/workstations/
  # and ensure they also have a README.md (next test).
  # This avoids failing on category directories.
  find "${REPO_ROOT}/apps/workstations" -type f -name "Dockerfile" -exec dirname {} \; | while read -r img_dir; do
    [ -f "${img_dir}/Dockerfile" ]
  done
}

@test "Every image in apps/workstations/ must have a README.md" {
  find "${REPO_ROOT}/apps/workstations" -type f -name "Dockerfile" -exec dirname {} \; | while read -r img_dir; do
    [ -f "${img_dir}/README.md" ]
  done
}
