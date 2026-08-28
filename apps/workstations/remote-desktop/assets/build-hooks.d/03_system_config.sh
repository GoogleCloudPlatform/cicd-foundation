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

set -euo pipefail

configure_system() {
  echo "Configuring system settings and rendering templates..."

  # Dynamic setup for systemd units and other configs
  /sbin/ldconfig -Xv

  export DESKTOP_SERVICE="gnome-session@user.service"
  # These variables should be available from the build environment
  envsubst '${GUACAMOLE_VERSION} ${DESKTOP_SERVICE} ${CONTAINER_REGISTRY}' < /etc/systemd/system/guacd.service.template > /etc/systemd/system/guacd.service
  envsubst '${GUACAMOLE_VERSION} ${DESKTOP_SERVICE} ${CONTAINER_REGISTRY}' < /etc/systemd/system/guacamole.service.template > /etc/systemd/system/guacamole.service
  envsubst '${DESKTOP_SERVICE}' < /etc/systemd/system/multi-user.target.d/20-desktop.conf.template > /etc/systemd/system/multi-user.target.d/20-desktop.conf

  # Package custom Guacamole extensions from source if present
  if [[ -d "/etc/guacamole/extensions/guacamole-audio-bridge" ]]; then
    export DEFAULT_ENABLE_AUDIO_INPUT="${DEFAULT_ENABLE_AUDIO_INPUT:-false}"
    envsubst '${DEFAULT_ENABLE_AUDIO_INPUT}' < /etc/guacamole/extensions/guacamole-audio-bridge/audio-bridge.js > /etc/guacamole/extensions/guacamole-audio-bridge/audio-bridge.js.tmp
    mv /etc/guacamole/extensions/guacamole-audio-bridge/audio-bridge.js.tmp /etc/guacamole/extensions/guacamole-audio-bridge/audio-bridge.js
    (
      cd /etc/guacamole/extensions/guacamole-audio-bridge
      zip -q -r /etc/guacamole/extensions/guacamole-audio-bridge.jar .
    )
    rm -rf /etc/guacamole/extensions/guacamole-audio-bridge
  fi

  # Clean up templates and default files
  rm -f /etc/systemd/system/guacd.service.template /etc/systemd/system/guacamole.service.template /etc/systemd/system/multi-user.target.d/20-desktop.conf.template
  chmod -x /usr/lib/ubuntu-release-upgrader/check-new-release-gtk
}

main() {
  configure_system
}

main "$@"
