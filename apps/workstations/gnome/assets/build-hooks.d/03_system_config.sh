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
  glib-compile-schemas /usr/share/glib-2.0/schemas

  export DESKTOP_SERVICE="gnome-session@user.service"
  # These variables should be available from the build environment
  envsubst '${GUACAMOLE_VERSION} ${DESKTOP_SERVICE} ${CONTAINER_REGISTRY}' < /etc/systemd/system/guacd.service.template > /etc/systemd/system/guacd.service
  envsubst '${GUACAMOLE_VERSION} ${DESKTOP_SERVICE} ${CONTAINER_REGISTRY}' < /etc/systemd/system/guacamole.service.template > /etc/systemd/system/guacamole.service

  # Clean up templates and default files
  rm -f /etc/systemd/system/guacd.service.template /etc/systemd/system/guacamole.service.template
  chmod -x /usr/lib/ubuntu-release-upgrader/check-new-release-gtk
}

main() {
  configure_system
}

main "$@"
