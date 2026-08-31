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

IMAGES_DIR="${1:-/opt/images}"

main() {
  if [[ -d "${IMAGES_DIR}" ]]; then
    for tarball in "${IMAGES_DIR}"/*.tar; do
      if [[ -f "${tarball}" ]]; then
        echo "Loading cached container image: ${tarball}..."
        docker load -i "${tarball}" || echo "Warning: Failed to load ${tarball}"
      fi
    done
    # Ensure local devcontainer-intellij:latest tag is present
    docker tag us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest devcontainer-intellij:latest 2>/dev/null || true
  fi

}

main "$@"
