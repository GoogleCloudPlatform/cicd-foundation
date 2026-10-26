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

# Remote Desktop Cloud Workstation Layer (`remote-desktop`)

## Overview

Intermediate graphical transport layer built on top of `preflight` that provides
browser-based remote desktop access via Apache Guacamole (`guacd` and
`guacamole` containers), TigerVNC (`tigervnc.service`), Chrome Remote Desktop
(`CRD`), and a bidirectional WebSocket PulseAudio bridge (`audio_streamer.js` +
`guacamole-audio-bridge` extension).

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains `03_system_config.sh` build hooks, the `guacamole-audio-bridge`
  extension, and `/google/scripts` (`audio_streamer.js`,
  `chrome_remote_desktop_setup.sh`, `fetch_guacamole.sh`).

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): `/build-hooks.d/03_system_config.sh`,
  `/etc/guacamole/extensions/guacamole-audio-bridge`,
  `/google/scripts/audio_streamer.js`,
  `/google/scripts/chrome_remote_desktop_setup.sh`,
  `/google/scripts/fetch_guacamole.sh`, and
  `/usr/local/bin/google-chrome-stable`.

## Invariants

- Pre-fetches `guacd` and `guacamole` Docker image tarballs into `/opt/images`
  during image build when `INSTALL_GUACAMOLE=true` and streams 44.1kHz 16-bit
  PCM audio between `/audio/ws` and local PulseAudio.

## Side Effects

- Installs X11/Wayland/PulseAudio/VNC/CRD dependencies, packages
  `guacamole-audio-bridge.jar`, renders Guacamole systemd units, and runs
  `audio-streamer.service`, `guacd.service`, and `guacamole.service` at
  runtime.
