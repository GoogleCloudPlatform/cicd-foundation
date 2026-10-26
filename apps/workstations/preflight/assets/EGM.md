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

# Preflight Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `preflight` Cloud Workstation layer,
containing Nginx/systemd/profile configurations (`etc`) and runtime
configuration rendering, backend readiness probing, and SPA build scripts
(`google`).

## Subdirectories & Boundaries

- **System Configuration**: [`./etc/EGM.md`](./etc/EGM.md) - Provides Nginx
  reverse-proxy templates, `config-rendering.service` and
  `backend-readiness.service` systemd units, XDG autostart entries, and
  `profile.d/99-setup-workstation.sh`.
- **Google Assets**: [`./google/EGM.md`](./google/EGM.md) - Provides
  `config_rendering.sh`, `backend_readiness_probe.sh`, and
  `scripts/build/build_web.sh`.

## Interface

- [`./etc/EGM.md`](./etc/EGM.md): `profile.d/99-setup-workstation.sh`,
  `nginx/sites-available/default.template`,
  `systemd/system/config-rendering.service`, and
  `systemd/system/backend-readiness.service`.
- [`./google/EGM.md`](./google/EGM.md): `scripts/config_rendering.sh`,
  `scripts/backend_readiness_probe.sh`, and `scripts/build/build_web.sh`.

## Invariants

- `config-rendering.service` renders Nginx, Guacamole, and `config.js`
  templates and writes `/run/config-rendered` before Nginx starts, while
  `backend-readiness.service` writes `/run/readiness/all` only after all
  configured protocol probes succeed.

## Side Effects

- Generates `/tmp/workstation/ephemeral.env`, renders
  `/var/www/html/config.js` and `/etc/nginx/sites-available/default`, probes
  backend ports, populates `/run/readiness/*`, and triggers
  `setup-workstation` on interactive login.
