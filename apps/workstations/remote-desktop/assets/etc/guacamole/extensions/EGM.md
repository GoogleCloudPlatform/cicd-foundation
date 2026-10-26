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

# Guacamole Extensions (`extensions`)

## Overview

Houses custom Apache Guacamole client extensions packaged into
`/etc/guacamole/extensions` for the `remote-desktop` workstation layer.

## Subdirectories & Boundaries

- **Guacamole Audio Bridge**:
  [`./guacamole-audio-bridge/EGM.md`](./guacamole-audio-bridge/EGM.md) -
  Streams bidirectional 16-bit 44.1kHz PCM audio between browser
  WebAudio/MediaDevices APIs and the `/audio/ws` WebSocket endpoint.

## Interface

- [`./guacamole-audio-bridge/EGM.md`](./guacamole-audio-bridge/EGM.md):
  `guac-manifest.json` (`guac-audio-bridge`) and `audio-bridge.js`.

## Invariants

- Extensions conform to the Apache Guacamole 1.6.0 manifest schema and stream
  44.1kHz 16-bit PCM audio over `/audio/ws`.

## Side Effects

- Injects `audio-bridge.js` into the Guacamole web client, establishing
  `/audio/ws` WebSocket connections and accessing browser audio playback and
  microphone APIs.
