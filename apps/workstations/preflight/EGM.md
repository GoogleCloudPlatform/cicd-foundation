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

# Preflight Cloud Workstation Layer (`preflight`)

## Overview

Intermediate Cloud Workstation layer built on `common` that serves the Custom
Image Preflight SPA (`preflight-web`) via Nginx on port `80`, dynamically
renders runtime configuration and ephemeral credentials (`config_rendering.sh`),
probes backend protocol readiness (`backend_readiness_probe.sh` -> `/readyz`),
and provides the `update-preflight` agent skill for live frontend hot-patching.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains Nginx/systemd configurations, `profile.d/99-setup-workstation.sh`,
  `config_rendering.sh`, `backend_readiness_probe.sh`, and `build_web.sh`.
- **Agent Skills**: [`./skills/EGM.md`](./skills/EGM.md) - Contains the
  `update-preflight` skill
  ([`./skills/update-preflight/SKILL.md`](./skills/update-preflight/SKILL.md))
  and scripts for testing and hot-patching `preflight-web` onto a live
  workstation.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): `/google/scripts/config_rendering.sh`,
  `/google/scripts/backend_readiness_probe.sh`,
  `/google/scripts/build/build_web.sh`, and
  `/etc/profile.d/99-setup-workstation.sh`.
- [`./skills/EGM.md`](./skills/EGM.md):
  `skills/update-preflight/scripts/test_and_hotpatch.sh` and
  `skills/update-preflight/scripts/hotpatch_frontend.sh`.

## Invariants

- Nginx serves `/startup.html` and `/readyz` on port `80`, returning
  `x-app-status: STARTING` until `backend_readiness_probe.sh` populates
  `/run/readiness/<protocol>` and `/run/readiness/all`.
- `config_rendering.sh` restricts `envsubst` to a 28-variable allowlist and is
  idempotent via `/run/config-rendered`.

## Side Effects

- Compiles and installs `preflight-web` into `/var/www/html` during Docker
  build, renders runtime templates and ephemeral credentials at boot, and
  probes local SSH/HTTP/RDP/VNC ports.
