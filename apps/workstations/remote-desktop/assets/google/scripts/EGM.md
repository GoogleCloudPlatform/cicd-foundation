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

# Remote Desktop Google Scripts (`scripts`)

## Overview

Contains build-time and runtime scripts supporting the `remote-desktop`
workstation layer: `fetch_guacamole.sh` fetches Apache Guacamole container
images (`guacd`, `guacamole`) via `crane` and extension `.jar` archives at build
time; `chrome_remote_desktop_setup.sh` configures user directories/groups and
starts Chrome Remote Desktop (`CRD`) at runtime if installed and configured; and
`audio_streamer.js` runs a local HTTP/WebSocket server on `127.0.0.1` that
streams stereo PCM audio captured via `parec` to connected WebSocket clients and
pipes incoming binary WebSocket frames (microphone input) to `pacat`.

## Interface

- `audio_streamer.js`: Executable Node.js HTTP/WebSocket server listening on
  `127.0.0.1:${AUDIO_STREAMER_PORT:-8081}`; exposes HTTP GET `/`, `/livez`,
  `/healthz` (`200 OK`) and WebSocket upgrade endpoint streaming 44100Hz
  2-channel `s16le` audio frames (`0x02`) and accepting incoming binary
  microphone audio frames (`0x02`, 44100Hz 1-channel `s16le`), ping (`0x09`),
  and close (`0x08`) frames; functions `broadcastFrame(buffer)`,
  `startRecorder()`, `stopRecorderIfIdle()`, `encodeWebSocketFrame(payload,
opcode)`, and `parseWebSocketFrames(buffer, onMessage)`; reads
  `AUDIO_STREAMER_PORT` and `PULSE_SERVER`.
- `chrome_remote_desktop_setup.sh`: Runtime setup script sourcing
  `/google/scripts/common.sh`; defines `setup_pki(home_dir, target_user)`,
  `setup_groups(target_user)`, `start_service(target_user, config_dir)`, and
  `main(...)`.
- `fetch_guacamole.sh`: Build-time asset fetcher script sourcing
  `/google/scripts/build/install_functions.sh`; defines `fetch_images()`,
  `fetch_extensions()`, and `main(...)`; reads `ENABLE_GUACAMOLE`,
  `INSTALL_GUACAMOLE`, `GUACAMOLE_IMAGES`, `CONTAINER_REGISTRY`,
  `GUACAMOLE_VERSION`, `GUACAMOLE_EXTENSIONS`, and `GUACAMOLE_BASE_URL`.

## Invariants

- `audio_streamer.js` binds strictly to loopback (`127.0.0.1`) on
  `AUDIO_STREAMER_PORT` (default `8081`) and requires a `sec-websocket-key`
  header on HTTP `upgrade` requests, destroying the socket if absent.
- `audio_streamer.js` only runs the shared `parec` capture process while at
  least one WebSocket client is connected (`clients.size > 0`), killing it
  with `SIGTERM` when `clients.size === 0` (`stopRecorderIfIdle`) and
  auto-restarting after 1000ms (on exit) or 2000ms (on error) if clients
  remain connected.
- `chrome_remote_desktop_setup.sh` exits `0` immediately if
  `/opt/google/chrome-remote-desktop/chrome-remote-desktop` is not present,
  and only launches the service if at least one `host*.json` file exists in
  `/home/user/.config/chrome-remote-desktop`.
- `chrome_remote_desktop_setup.sh` enforces `700` permissions and `user:user`
  ownership on `/home/user/.pki`.
- `fetch_guacamole.sh` always creates `/downloads` before checking
  `ENABLE_GUACAMOLE`/`INSTALL_GUACAMOLE` so downstream Docker `COPY
--from=fetcher /downloads/ /` instructions succeed even when Guacamole is
  disabled.

## Side Effects

- `audio_streamer.js` binds a TCP listener on
  `127.0.0.1:${AUDIO_STREAMER_PORT:-8081}` and spawns child processes `parec`
  (shared across clients) and `pacat` (one per WebSocket client) connected to
  `PULSE_SERVER` (default `unix:/run/user/<uid>/pulse/native`).
- `chrome_remote_desktop_setup.sh` creates `/home/user/.pki/nssdb`,
  `/var/run/dbus`, and `/home/user/.config/chrome-remote-desktop`, updates
  file ownership/permissions, creates the `chrome-remote-desktop` group, adds
  `user` to the group, emits structured log events (`SERVICE_STARTING`,
  `SERVICE_READY`), and spawns
  `/opt/google/chrome-remote-desktop/chrome-remote-desktop --start` in the
  background as `user`.
- `fetch_guacamole.sh` creates `/downloads`, `/downloads/opt/images`, and
  `/downloads/etc/guacamole/extensions`, installs `crane` to
  `/usr/local/bin/crane` (via `fetch_crane`), pulls container image tarballs
  into `/downloads/opt/images/<image>.tar`, and downloads/extracts Guacamole
  extension `.jar` files into `/downloads/etc/guacamole/extensions`.
