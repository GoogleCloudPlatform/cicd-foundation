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

# GNOME Build Hooks (`build-hooks.d`)

## Overview

Contains three build-time hook scripts executed in alphabetical order by
`/google/scripts/build/configure_workstation.sh`:
`01_install_gnome_extensions.sh` installs, patches, and compiles schemas for
GNOME Shell extensions; `03_system_config.sh` updates dynamic linker/GLib/dconf
caches, renders systemd unit templates for Guacamole and the GNOME desktop
target, and disables the Ubuntu release upgrader prompt; and
`99_setup_desktop.sh` registers core desktop applications (Chrome, Nautilus,
GNOME Terminal) as dock favorites with explicit ordering priorities.

## Interface

- `01_install_gnome_extensions.sh`: `install_extensions()` and `main()`; reads
  `GNOME_SHELL_EXTENSIONS` (space-separated `ext_id@domain:version` pairs) and
  `CURL_OPTS`.
- `03_system_config.sh`: `configure_system()` and `main()`; renders
  `/etc/systemd/system/guacd.service`,
  `/etc/systemd/system/guacamole.service`, and
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf` from `.template`
  files using `GUACAMOLE_VERSION`, `CONTAINER_REGISTRY`, and
  `DESKTOP_SERVICE="gnome-session@user.service
gnome-remote-desktop@user.service"`.
- `99_setup_desktop.sh`: `main()`; sources
  `/google/scripts/build/desktop_integration.sh` and invokes
  `desktop_register_app <desktop_file> <priority> <autostart> <favorite>` for
  core GNOME desktop applications.

## Invariants

- All three hook scripts run with Bash strict mode (`set -euo pipefail`) and
  invoke `main "$@"` unconditionally at top-level.
- Hooks execute in lexical order (`01_install_gnome_extensions.sh` ->
  `03_system_config.sh` -> `99_setup_desktop.sh`) via `run_hooks` in
  `configure_workstation.sh`.
- In `01_install_gnome_extensions.sh`, if `GNOME_SHELL_EXTENSIONS` is empty or
  unset, it exits early with status `0`; otherwise each
  `<ext_id>:<ext_version>` archive is fetched from
  `extensions.gnome.org/extension-data/` (with `@` stripped) or fallback
  `extensions.gnome.org/download-extension/` (with `@` encoded as `%40`), and
  `/usr/share/gnome-shell/extensions/<ext_id>/` permissions are recursively
  set to `755`.
- In `03_system_config.sh`, `DESKTOP_SERVICE` is exported as
  `"gnome-session@user.service gnome-remote-desktop@user.service"`, and
  template source files (`/etc/systemd/system/guacd.service.template`,
  `/etc/systemd/system/guacamole.service.template`,
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf.template`) must
  exist on the filesystem.
- In `99_setup_desktop.sh`, core applications are pinned to the dock
  (`favorite=true`) without autostart (`autostart=false`) in strict priority
  order: `google-chrome.desktop` (`10`), `org.gnome.Nautilus.desktop` (`20`),
  and `org.gnome.Terminal.desktop` (`30`), only if their respective `.desktop`
  files exist in `/usr/share/applications`.

## Side Effects

- `01_install_gnome_extensions.sh`: Downloads extension zip archives from
  `https://extensions.gnome.org`, unpacks them into
  `/usr/share/gnome-shell/extensions/<ext_id>/`, appends
  `stylesheet-patch.css` to `stylesheet.css` for
  `just-perfection-desktop@just-perfection`, copies extension `*.gschema.xml`
  files to `/usr/share/glib-2.0/schemas/`, sets `755` permissions on extension
  directories, and runs `glib-compile-schemas`.
- `03_system_config.sh`: Runs `/sbin/ldconfig -Xv`, `glib-compile-schemas
/usr/share/glib-2.0/schemas`, and `dconf update || true`, writes rendered
  systemd files `/etc/systemd/system/guacd.service`,
  `/etc/systemd/system/guacamole.service`, and
  `/etc/systemd/system/multi-user.target.d/20-desktop.conf` via `envsubst`,
  deletes the corresponding `.template` files (`rm -f`), and removes execute
  permissions (`chmod -x`) from
  `/usr/lib/ubuntu-release-upgrader/check-new-release-gtk`.
- `99_setup_desktop.sh`: Mutates
  `/usr/share/applications/google-chrome.desktop`,
  `/usr/share/applications/org.gnome.Nautilus.desktop`, and
  `/usr/share/applications/org.gnome.Terminal.desktop` in-place via
  `desktop_register_app`.
