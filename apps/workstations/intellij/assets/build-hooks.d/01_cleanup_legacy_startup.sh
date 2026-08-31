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

# Remove legacy workstation startup scripts inherited from predefined base image
# to prevent execution before systemd and user setup initialization, and prevent
# port 80 collisions with Nginx (preflight dashboard) and port 22 conflicts with systemd sshd.
rm -f /etc/workstation-startup.d/110_start-intellij-ultimate.sh \
      /etc/workstation-startup.d/130_jetbrains-ready-server.sh \
      /etc/workstation-startup.d/020_start-sshd.sh
