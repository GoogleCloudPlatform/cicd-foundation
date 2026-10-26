<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Remote Desktop Build Hooks (`build-hooks.d`)

## Overview

Build-time hook script (`03_system_config.sh`) for the `remote-desktop`
workstation layer that updates the dynamic linker cache, renders systemd unit
and drop-in templates for Guacamole and the desktop target, packages the
`guacamole-audio-bridge` extension into a JAR if present, deletes rendered
template sources, and disables the Ubuntu release upgrader GTK check.

## Interface

- `03_system_config.sh`: Build hook executable script defining
  `configure_system()` and `main()`.
- Environment inputs: `GUACAMOLE_VERSION`, `CONTAINER_REGISTRY`, and
  `DEFAULT_ENABLE_AUDIO_INPUT` (defaults to `'false'`).
- Environment export: `DESKTOP_SERVICE="gnome-session@user.service"`.

## Invariants

- Executes under strict shell mode (`set -euo pipefail`).
- `DESKTOP_SERVICE` is fixed to `'gnome-session@user.service'` for all
  rendered systemd templates.
- `DEFAULT_ENABLE_AUDIO_INPUT` defaults to `'false'` when unset or empty
  during `guacamole-audio-bridge` packaging.
- Expects `/etc/systemd/system/guacd.service.template`,
  `/etc/systemd/system/guacamole.service.template`,
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf.template`, and
  `/usr/lib/ubuntu-release-upgrader/check-new-release-gtk` to exist at
  execution time.

## Side Effects

- Runs `/sbin/ldconfig -Xv` to rebuild the shared library cache and links.
- Writes `/etc/systemd/system/guacd.service`,
  `/etc/systemd/system/guacamole.service`, and
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf` via `envsubst`.
- If `/etc/guacamole/extensions/guacamole-audio-bridge` exists, renders
  `audio-bridge.js` in-place, creates
  `/etc/guacamole/extensions/guacamole-audio-bridge.jar` via `zip`, and
  deletes the `/etc/guacamole/extensions/guacamole-audio-bridge` directory.
- Deletes `/etc/systemd/system/guacd.service.template`,
  `/etc/systemd/system/guacamole.service.template`, and
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf.template`.
- Removes executable permissions (`chmod -x`) from
  `/usr/lib/ubuntu-release-upgrader/check-new-release-gtk`.
