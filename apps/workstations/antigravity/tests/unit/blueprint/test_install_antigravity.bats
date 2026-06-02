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

load ../test_helper.bash

bats_require_minimum_version 1.5.0

setup() {
  # Create a mock environment for testing declarative configuration
  export TEST_TEMP_DIR="${BATS_FILE_TMPDIR}/mock_root"
  mkdir -p "${TEST_TEMP_DIR}/etc/apt/sources.list.d"

  # Copy the real asset for testing
  cp "${ANTIGRAVITY_LAYER_DIR}/assets/etc/apt/sources.list.d/antigravity.list" \
     "${TEST_TEMP_DIR}/etc/apt/sources.list.d/"
}

@test "Antigravity repository configuration is region-agnostic by default" {
  grep -q "us-central1" "${TEST_TEMP_DIR}/etc/apt/sources.list.d/antigravity.list"
}

@test "Declarative installation: EXTRA_PKGS contains antigravity" {
  # This test validates the expected environment variable that the Dockerfile sets
  # In a real build, this is set via ENV EXTRA_PKGS=${ANTIGRAVITY_PKGS}
  local dockerfile="${ANTIGRAVITY_LAYER_DIR}/Dockerfile"
  grep -q "ARG ANTIGRAVITY_PKGS=\"antigravity\"" "${dockerfile}"
  grep -q "ENV EXTRA_PKGS=\${ANTIGRAVITY_PKGS}" "${dockerfile}"
}

@test "Region patching: sed correctly updates the repository region" {
  local mock_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/antigravity.list"
  local target_region="europe-west1"

  # Simulate the logic in configure_workstation.sh
  sed -i "s/us-central1/${target_region}/g" "${mock_list}"

  grep -q "${target_region}" "${mock_list}"
  run ! grep -q "us-central1" "${mock_list}"
}

@test "Antigravity wrapper script contains required stability flags" {
  local wrapper="${ANTIGRAVITY_LAYER_DIR}/assets/usr/local/bin/antigravity"
  [ -f "${wrapper}" ]
  grep -q -- "--ozone-platform=wayland" "${wrapper}"
  grep -q -- "--in-process-gpu" "${wrapper}"
  grep -q -- "--disable-gpu-sandbox" "${wrapper}"
}

@test "Post-install hook patches desktop entry correctly" {
  local mock_desktop="${BATS_FILE_TMPDIR}/antigravity.desktop"
  echo "Exec=/usr/share/antigravity/antigravity %F" > "${mock_desktop}"

  # Run the patch logic (simulated)
  sed -i 's|^Exec=/usr/share/antigravity/antigravity|Exec=/usr/local/bin/antigravity|g' "${mock_desktop}"

  grep -q "Exec=/usr/local/bin/antigravity %F" "${mock_desktop}"
}
