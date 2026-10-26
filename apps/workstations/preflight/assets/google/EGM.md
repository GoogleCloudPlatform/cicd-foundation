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

# Preflight Google Assets (`google`)

## Overview

Houses Google-managed runtime configuration scripts, `setup-workstation` default
templates (`etc/setup-workstation.yaml.example`), logging templates
(`templates/log.json.template`), and SPA build hooks under `/google` for the
`preflight` Cloud Workstation layer.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Implements
  `config_rendering.sh` (ephemeral credentials and template rendering),
  `backend_readiness_probe.sh` (multi-protocol readiness checks), and
  `./scripts/build/build_web.sh` (Preflight SPA build staging).

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): `config_rendering.sh`,
  `backend_readiness_probe.sh`, and `build/build_web.sh`.

## Invariants

- Configuration rendering (`/run/config-rendered`) completes before Nginx and
  Guacamole services start, and backend readiness (`/run/readiness/all`)
  requires all configured protocol probes (`ssh`, `rdp`, `vnc`, `http`) to
  succeed.

## Side Effects

- Generates `/tmp/workstation/ephemeral.env`, renders
  Nginx/Guacamole/`config.js` templates, probes local service ports, and
  populates `/run/readiness/*` status files.
