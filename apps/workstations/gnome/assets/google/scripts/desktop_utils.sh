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

# desktop_utils.sh: Runtime utilities for desktop environment stability.

readonly DESKTOP_POLL_INTERVAL=0.1

# wait_for_monitor: Polls Mutter's DisplayConfig via DBus until at least one
# active monitor is reported by GNOME Shell.
#
# In headless cloud environments, GNOME Shell may start before a virtual monitor
# is fully initialized (e.g., waiting for a Guacamole/RDP connection).
# Launching graphics-intensive or Java/AWT applications before a monitor is
# available can lead to startup failures or "no screen devices" errors.
#
# Arguments:
#   $1: Timeout in seconds (default: 60)
wait_for_monitor() {
  local timeout="${1:-60}"
  local elapsed=0

  # Ensure critical environment variables are set for the monitor check.
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
  # Ensure gdbus can find the session bus
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

  # We check for 'is-current' which indicates an active, usable monitor in GNOME's state.
  until gdbus call --session \
                   --dest org.gnome.Mutter.DisplayConfig \
                   --object-path /org/gnome/Mutter/DisplayConfig \
                   --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null | grep -q "is-current"; do
    if (( $(echo "${elapsed} >= ${timeout}" | bc -l) )); then
      # If we time out, we proceed anyway as a best-effort fallback.
      break
    fi
    sleep "${DESKTOP_POLL_INTERVAL}"
    elapsed=$(echo "${elapsed} + ${DESKTOP_POLL_INTERVAL}" | bc -l)
  done
}
