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

# Guacamole Configuration (`guacamole`)

## Overview

Contains Apache Guacamole configuration templates (`user-mapping.xml.template`)
and custom extensions under `/etc/guacamole` for the `remote-desktop` layer.

## Subdirectories & Boundaries

- **Extensions**: [`./extensions/EGM.md`](./extensions/EGM.md) - Packages the
  `guacamole-audio-bridge` WebAudio streaming extension.

## Interface

- [`./extensions/EGM.md`](./extensions/EGM.md): Guacamole client extensions
  (`guacamole-audio-bridge`).
- `user-mapping.xml.template`: Template for Guacamole VNC/RDP connection
  mapping.

## Invariants

- Guacamole extensions must reside under `./extensions` and adhere to
  Guacamole 1.6.0 manifest specifications.

## Side Effects

- Configures Guacamole client extensions and connection mappings loaded by the
  Guacamole web application.
