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

# Remote Desktop Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `remote-desktop` Cloud Workstation
layer, containing Guacamole and systemd template rendering hooks
(`build-hooks.d`), Guacamole audio bridge extension and system configs (`etc`),
and PulseAudio WebSocket streaming, CRD setup, and Guacamole fetcher scripts
(`google`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Renders Guacamole/desktop systemd templates and packages
  `guacamole-audio-bridge.jar` via `03_system_config.sh`.
- **System Configuration**: [`./etc/EGM.md`](./etc/EGM.md) - Contains
  `guacamole/extensions/guacamole-audio-bridge`, `profile.d/google-bin.sh`,
  and systemd service templates.
- **Google Scripts**: [`./google/EGM.md`](./google/EGM.md) - Provides
  `audio_streamer.js`, `chrome_remote_desktop_setup.sh`, and
  `fetch_guacamole.sh`.
- **User Binaries** (`./usr/local/bin`): Provides the `google-chrome-stable`
  wrapper script that initializes `gnome-keyring-daemon` and launches
  `/usr/bin/google-chrome-stable` with container and GPU/Wayland stability
  flags.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md): `03_system_config.sh`
  (`configure_system`, `main`).
- [`./etc/EGM.md`](./etc/EGM.md):
  `guacamole/extensions/guacamole-audio-bridge` (`audio-bridge.js`,
  `guac-manifest.json`) and `profile.d/google-bin.sh`.
- [`./google/EGM.md`](./google/EGM.md): `scripts/audio_streamer.js`,
  `scripts/chrome_remote_desktop_setup.sh`, and `scripts/fetch_guacamole.sh`.
- `usr/local/bin/google-chrome-stable`: Google Chrome container stability and
  keyring wrapper.

## Invariants

- Packages `guacamole-audio-bridge` into
  `/etc/guacamole/extensions/guacamole-audio-bridge.jar` during image build
  and binds `audio_streamer.js` strictly to
  `127.0.0.1:${AUDIO_STREAMER_PORT:-8081}`.

## Side Effects

- Fetches Guacamole container tarballs, compiles `guacamole-audio-bridge.jar`,
  renders `guacd`/`guacamole` systemd units, starts CRD when configured, and
  bridges browser WebAudio with PulseAudio (`parec`/`pacat`).
