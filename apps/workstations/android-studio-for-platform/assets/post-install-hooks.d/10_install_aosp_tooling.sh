#!/bin/bash

# Copyright 2024-2026 Google LLC
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

# Sourced logic (from preflight or local)
# shellcheck disable=SC1091
source "/google/scripts/common.sh"

install_aosp_tooling() {
  local apt_opts="${APT_OPTS:--y --no-install-recommends}"

  echo "Installing Cuttlefish from /cuttlefish..."
  pushd /cuttlefish > /dev/null
  # shellcheck disable=SC2086
  apt-get install ${apt_opts} ./cuttlefish-base_*.deb ./cuttlefish-user_*.deb
  popd > /dev/null

  ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
  ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

  log "Cleaning up /cuttlefish artifacts..."
  rm -rf /cuttlefish
}

main() {
  install_aosp_tooling
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
