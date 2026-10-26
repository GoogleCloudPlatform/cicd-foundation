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

# GNOME Google Scripts (`scripts`)

## Overview

Provides runtime orchestration, RDP and Chrome Remote Desktop (`CRD`)
pre-configuration, GNOME user/session initialization, and display/RDP readiness
utilities for headless Wayland GNOME sessions in Cloud Workstations, alongside
build-time desktop application registration and GSettings schema overrides in
`./build`.

## Interface

- `desktop_utils.sh`: `wait_for_monitor [timeout=60]` (polls
  `org.gnome.Mutter.DisplayConfig.GetCurrentState` over session D-Bus until
  `is-current` is reported, then sleeps `APP_STARTUP_DELAY`),
  `DESKTOP_POLL_INTERVAL=0.1`, and `APP_STARTUP_DELAY` (env var, default `0`).
- `start_gnome_session.sh [target_user=$WORKSTATION_USER]`: `main` and
  `setup_environment` (executes headless Wayland GNOME session for systemd
  `gnome-session@.service`).
- `configure_rdp.sh [target_user=$WORKSTATION_USER]`: `main` (`ExecStartPre`
  script for `gnome-remote-desktop@.service` that configures TLS certificates
  and RDP credentials via `grdctl`).
- `gnome_setup.sh`: `main`, `wait_for_extension <ext_id>`, `setup_rdp_certs`,
  `setup_browser`, `setup_gnome_settings`, and `EXTENSION_READY_TIMEOUT=15`
  (invoked by `gnome-setup.service`).
- `chrome_remote_desktop_setup.sh`: `main`, `setup_pki <home_dir>
<target_user>`, `setup_groups <target_user>`, and `start_service
<target_user> <config_dir>` (invoked by
  `chrome-remote-desktop-setup.service`).
- `layer_readiness_probe.sh`: `main` (polls `journalctl -u
gnome-remote-desktop@${target_user}.service` for `"RDP server started"`
  within `BACKEND_PROBE_TIMEOUT`, default `600`s).
- **Build Scripts**: [`./build/EGM.md`](./build/EGM.md) -
  `desktop_integration.sh` (`desktop_register_app`,
  `desktop_apply_integration`, `WORKSTATION_DEFAULT_APP`).

## Invariants

- `configure_rdp.sh` requires `EPHEMERAL_ENV_PATH` to exist within 60 seconds
  and define a non-empty `EPHEMERAL_PASS`, or it exits with status `1`.
- `start_gnome_session.sh` enforces Wayland session variables
  (`WAYLAND_DISPLAY=wayland-0`, `XDG_SESSION_TYPE=wayland`,
  `GDK_BACKEND=wayland`, `QT_QPA_PLATFORM=wayland`, `CLUTTER_BACKEND=wayland`,
  `SDL_VIDEODRIVER=wayland`) and forces LLVMpipe software rendering
  (`LIBGL_ALWAYS_SOFTWARE=1`, `GALLIUM_DRIVER=llvmpipe`,
  `MESA_LOADER_DRIVER_OVERRIDE=swrast`) when `WORKSTATION_GPU_ENABLED` is
  `'false'`.
- `start_gnome_session.sh` blocks readiness notification until
  `org.gnome.Shell.ShellVersion` is queryable over session D-Bus, exiting with
  status `1` if `gnome-session-binary` terminates early, and waits on the
  background session PID so systemd does not prematurely restart the unit.
- `gnome_setup.sh` is idempotent across restarts via the
  `/run/gnome-setup-done` sentinel file.
- `layer_readiness_probe.sh` requires
  `gnome-remote-desktop@${target_user}.service` journal logs to contain `"RDP
server started"` within `BACKEND_PROBE_TIMEOUT` (default `600`s) before
  returning `0`.

## Side Effects

- `start_gnome_session.sh` spawns a managed session `dbus-daemon` if
  `/run/user/<uid>/bus` is absent after 5 seconds, kills stale user processes
  (`gnome-session`, `gnome-shell`, `gnome-remote-de`), wipes and recreates
  `/home/<user>/.local/share/keyrings` with a `login` default keyring unlocked
  with a blank password, starts `/usr/libexec/gnome-session-binary
--session=ubuntu`, enables the `just-perfection-desktop@just-perfection`
  extension, and sends `systemd-notify --ready`.
- `configure_rdp.sh` and `gnome_setup.sh` create
  `/home/<user>/.local/share/gnome-remote-desktop`, generate `rdp-tls.crt` and
  `rdp-tls.key` via `winpr-makecert3`/`winpr3-makecert`/`winpr-makecert`
  (stripping null bytes) if missing, and `configure_rdp.sh` invokes `grdctl
--headless rdp` to configure TLS key/cert, credentials, port `3389`,
  view-only mode disabled, and enable RDP.
- `gnome_setup.sh` removes legacy user systemd overrides, sets
  `google-chrome.desktop` as the default browser via
  `xdg-mime`/`xdg-settings`, configures
  `org.gnome.shell.extensions.just-perfection` via `gsettings`, emits
  `SERVICE_STARTING`/`SERVICE_READY` events, and touches
  `/run/gnome-setup-done`.
- `chrome_remote_desktop_setup.sh` initializes `~/.pki/nssdb` (`chmod 700`),
  adds `user` to `chrome-remote-desktop` group, creates `/var/run/dbus`, and
  starts `/opt/google/chrome-remote-desktop/chrome-remote-desktop --start`
  when `host*.json` exists.
- `desktop_utils.sh` (`wait_for_monitor`) exports `XDG_RUNTIME_DIR`,
  `WAYLAND_DISPLAY`, and `DBUS_SESSION_BUS_ADDRESS` in the caller's
  environment and queries the session D-Bus.
