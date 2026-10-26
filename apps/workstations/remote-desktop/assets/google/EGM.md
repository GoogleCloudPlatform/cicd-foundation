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

# Remote Desktop Google Assets (`google`)

## Overview

Houses Google-managed build-time Guacamole fetcher scripts and runtime
PulseAudio WebSocket streaming and Chrome Remote Desktop (`CRD`) setup scripts
under `/google` for the `remote-desktop` Cloud Workstation layer.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides
  `audio_streamer.js` (`127.0.0.1:8081` PulseAudio WebSocket bridge),
  `chrome_remote_desktop_setup.sh`, and `fetch_guacamole.sh`.

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): `audio_streamer.js`,
  `chrome_remote_desktop_setup.sh`, and `fetch_guacamole.sh`.

## Invariants

- `audio_streamer.js` binds strictly to `127.0.0.1` and only runs `parec`
  while WebSocket clients are connected; `fetch_guacamole.sh` guarantees
  `/downloads` exists for multi-stage Docker copies.

## Side Effects

- Pulls Guacamole container images (`guacd.tar`, `guacamole.tar`) and
  extensions at build time, configures/starts CRD at boot, and streams
  bidirectional PulseAudio PCM frames over WebSockets.
