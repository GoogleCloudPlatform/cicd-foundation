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

configure_template() {
  local template_dir="/opt/devcontainer/intellij"
  local skel_dir="/etc/skel/.devcontainer"

  if [[ -f "${template_dir}/devcontainer.json" ]]; then
    echo "Transforming devcontainer.json to use prebuilt image..."
    jq 'del(.build) | .image = "devcontainer-intellij:latest"' "${template_dir}/devcontainer.json" > "${template_dir}/devcontainer.json.tmp"
    mv "${template_dir}/devcontainer.json.tmp" "${template_dir}/devcontainer.json"

    mkdir -p "${skel_dir}"
    cp -r "${template_dir}/"* "${skel_dir}/"
  fi
}

main() {
  configure_template
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
