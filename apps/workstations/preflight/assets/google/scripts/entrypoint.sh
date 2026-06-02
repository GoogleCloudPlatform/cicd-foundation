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

# Entrypoint to run systemd on startup.

set -euo pipefail

main() {
  # Emit early boot signal for SLO monitoring
  # shellcheck source=/dev/null
  source /google/scripts/common.sh
  log_event IMAGE_BOOTING "Starting workstation boot sequence"

  # CRITICAL: Apply "Hard Silence" firewall immediately.
  # This drops external SYN packets instead of sending RSTs (Connection Refused),
  # forcing the CWS Gateway into a silent TCP retry loop until Nginx is ready.
  /google/scripts/traffic_control.sh block

  # journal to Cloud Logging
  /google/scripts/cloud_logging_setup.sh

  # Ensure a consistent machine-id across restarts by persisting it in the home directory.
  # This is required for services like Chrome Remote Desktop and GNOME settings.
  # shellcheck source=/dev/null
  source /google/scripts/machine_id_setup.sh

  # Hand over to start_systemd.sh which handles dynamic service enablement
  # and the final systemd initialization.
  exec /google/scripts/start_systemd.sh
}

main "$@"
