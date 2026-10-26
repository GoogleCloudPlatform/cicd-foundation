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

# Remote Desktop System Configuration (`etc`)

## Overview

System configuration files under `/etc` for the `remote-desktop` Cloud
Workstation layer, including APT keyrings/sources (`apt`), Apache Guacamole
configuration templates and audio bridge extension (`guacamole`), Chrome
policies (`opt/chrome`), Polkit rules (`polkit-1`), shell profile hooks
(`profile.d`), and systemd service definitions (`systemd`).

## Subdirectories & Boundaries

- **Guacamole Configuration & Extensions**:
  [`./guacamole/EGM.md`](./guacamole/EGM.md) - Contains
  `user-mapping.xml.template` and the `guacamole-audio-bridge` WebAudio
  streaming extension.
- **Profile Scripts**: [`./profile.d/EGM.md`](./profile.d/EGM.md) - Appends
  `/google/bin` to interactive `PATH` via `google-bin.sh`.

## Interface

- [`./guacamole/EGM.md`](./guacamole/EGM.md):
  `extensions/guacamole-audio-bridge` (`guac-manifest.json`,
  `audio-bridge.js`) and `user-mapping.xml.template`.
- [`./profile.d/EGM.md`](./profile.d/EGM.md): `google-bin.sh` (`PATH`).

## Invariants

- `guacamole-audio-bridge` streams 44.1kHz 16-bit PCM audio over `/audio/ws`
  and is packaged into `/etc/guacamole/extensions/guacamole-audio-bridge.jar`
  during image build.

## Side Effects

- Configures Guacamole extensions and connection mappings, updates shell
  `PATH`, and provides systemd units for `audio-streamer.service`,
  `tigervnc.service`, `guacd`, and `guacamole`.
