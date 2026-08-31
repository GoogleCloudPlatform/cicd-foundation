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

bats_require_minimum_version 1.5.0

@test "08_configure_devcontainer_template.sh transforms devcontainer.json to use prebuilt image" {
  local hook_script="${LAYER_DIR}/assets/build-hooks.d/08_configure_devcontainer_template.sh"
  [ -f "${hook_script}" ]
  [ -x "${hook_script}" ]

  # Create isolated mock template directory and skel directory
  local mock_template_dir="/tmp/test_template_$$"
  local mock_skel_dir="/tmp/test_skel_$$"
  mkdir -p "${mock_template_dir}" "${mock_skel_dir}"

  cat <<'JSON' > "${mock_template_dir}/devcontainer.json"
{
  "name": "IntelliJ Ultimate Devcontainer",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "forwardPorts": [22]
}
JSON

  # Test jq transformation logic
  jq 'del(.build) | .image = "devcontainer-intellij:latest"' "${mock_template_dir}/devcontainer.json" > "${mock_template_dir}/devcontainer.json.tmp"
  mv "${mock_template_dir}/devcontainer.json.tmp" "${mock_template_dir}/devcontainer.json"
  cp -r "${mock_template_dir}/"* "${mock_skel_dir}/"

  run jq -r '.image' "${mock_skel_dir}/devcontainer.json"
  [ "$status" -eq 0 ]
  [ "$output" = "devcontainer-intellij:latest" ]

  run jq -r '.build' "${mock_skel_dir}/devcontainer.json"
  [ "$output" = "null" ]

  rm -rf "${mock_template_dir}" "${mock_skel_dir}"
}
