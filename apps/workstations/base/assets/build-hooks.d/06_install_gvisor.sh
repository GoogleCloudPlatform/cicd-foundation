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

if [[ "${INSTALL_GVISOR:-false}" == "true" ]]; then
  echo "Installing gVisor..."
  
  GVISOR_VERSION=20260803.0
  GVISOR_X86_64_SHA512=266ff0c74ba4faf137837c051e1d3c0a331bb1d3c152d791f349ef6680542d089b81f68e3c9f196a6fb82263909cfc583c39e98a0e058bb29c5ab752d9432805
  GVISOR_AARCH64_SHA512=6548e3222a31b9f4029fd8ad4c78076ab336db9789f8fa0c68f3dbe410278b043e7dd18f283a44df248ac63b577082937777b727118af3388bec8c9cc9c931b8

  ARCH=$(uname -m)
  case "${ARCH}" in
      x86_64) SHA="${GVISOR_X86_64_SHA512}" ;;
      aarch64) SHA="${GVISOR_AARCH64_SHA512}" ;;
      *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;;
  esac

  URL="https://storage.googleapis.com/gvisor/releases/release/${GVISOR_VERSION}/${ARCH}"
  wget -q ${URL}/gvisor.tar.bz2
  echo "${SHA}  gvisor.tar.bz2" | sha512sum -c -
  tar -xjf gvisor.tar.bz2 -C /usr/local/bin
  rm -f gvisor.tar.bz2

  /usr/local/bin/runsc install
else
  echo "gVisor installation skipped."
fi
