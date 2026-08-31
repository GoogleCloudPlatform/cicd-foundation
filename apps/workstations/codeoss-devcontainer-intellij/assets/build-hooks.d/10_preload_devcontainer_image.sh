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

# shellcheck source=apps/workstations/common/assets/google/scripts/build/install_functions.sh
source /google/scripts/build/install_functions.sh

preload_devcontainer() {
  local image_id="${INTELLIJ_DEVCONTAINER_BASE_IMAGE:-us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest}"
  local output_tar="/opt/images/intellij-ultimate.tar"

  echo "Preloading IntelliJ devcontainer base image..."
  mkdir -p /opt/images
  fetch_crane
  fetch_image "${image_id}" "${output_tar}"
}

main() {
  preload_devcontainer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
