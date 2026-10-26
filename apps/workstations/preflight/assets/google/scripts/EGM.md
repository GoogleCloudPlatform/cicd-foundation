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

# Preflight Google Scripts (`scripts`)

## Overview

Provides boot-time ephemeral credential generation, Cloud Workstations metadata
discovery, runtime template rendering for Guacamole/Nginx/Preflight web
configuration, and permission hardening via `config_rendering.sh`,
multi-protocol backend readiness probing via `backend_readiness_probe.sh`, and
build-time Preflight SPA staging in `./build/build_web.sh`.

## Interface

- `config_rendering.sh`: `main "$@"` (boot-time configuration rendering
  entrypoint, invoked by `config-rendering.service`), `generate_credentials()`
  (exports `EPHEMERAL_PASS` and `AUTH_HEADER`), `save_credentials()` (writes
  `EPHEMERAL_PASS` and `AUTH_HEADER` to `${EPHEMERAL_ENV_PATH}`),
  `render_templates()` (resolves protocol/metadata/routing variables and
  renders `.template` files via `envsubst`), `fix_web_permissions()`
  (normalizes `/var/www/html` permissions), and `fix_script_permissions()`
  (normalizes `/google/scripts` and `/etc/workstation-startup.d` permissions).
- `backend_readiness_probe.sh`: `main "$@"` (invoked by
  `backend-readiness.service`), `check_port <port> [timeout]`,
  `wait_for_service <svc> [timeout]`, `probe_ssh()`, `probe_http [port]`,
  `probe_rdp [target_user]`, `probe_vnc()`, and
  `READINESS_DIR="/run/readiness"`.
- **Build Scripts**: [`./build/EGM.md`](./build/EGM.md) - `build_web.sh
<PREFLIGHT_WEB_REPO> <PREFLIGHT_WEB_DIR>` (`perform_build`) builds and
  stages the Preflight SPA into `/build/web/dist`.

## Invariants

- Both runtime scripts execute with strict bash flags (`set -euo pipefail`)
  and source `/google/scripts/common.sh`.
- `config_rendering.sh` is idempotent: `main` exits `0` immediately without
  modifying state if sentinel file `/run/config-rendered` exists.
- `config_rendering.sh` restricts `envsubst` template rendering to an explicit
  allowlist of 28 environment variables so unescaped Nginx variables in
  templates remain intact.
- Ephemeral credentials in `config_rendering.sh` are restricted to
  `root:${WORKSTATION_UID}` with mode `0750` on `${EPHEMERAL_ENV_DIR}` and
  `0640` on `${EPHEMERAL_ENV_PATH}`.
- `config_rendering.sh` avoids HTTP 302 redirect loops on root-mounted proxies
  by clearing `ROOT_REDIRECT_BLOCK` when `BACKEND_PROXY_PATH` is `'/'` and
  `DEFAULT_CLIENT_PROTOCOL` is not `'SSH'`.
- `backend_readiness_probe.sh` evaluates port readiness across both IPv4
  (`127.0.0.1`) and IPv6 (`::1`) via `/dev/tcp`, runs enabled protocol probes
  (`ssh`, `rdp`, `vnc`, `http`) in parallel, invokes
  `/google/scripts/layer_readiness_probe.sh` (if executable) during
  `probe_rdp`, honors `APP_STARTUP_DELAY`, and writes `"OK"` to
  `/run/readiness/<protocol>` and `/run/readiness/all` only when all spawned
  probes succeed.

## Side Effects

- `config_rendering.sh` creates `${EPHEMERAL_ENV_DIR}` (`/tmp/workstation`),
  writes `${EPHEMERAL_ENV_PATH}` (`/tmp/workstation/ephemeral.env`), reads
  `/etc/environment` and `/proc/1/environ`, queries GCP metadata endpoints
  (`http://metadata.google.internal`, `http://169.254.169.254`), renders
  `/etc/guacamole/user-mapping.xml`, `/etc/nginx/sites-available/default`, and
  `/var/www/html/config.js` from `.template` files, normalizes permissions on
  `/var/www/html`, `/google/scripts`, and `/etc/workstation-startup.d`, emits
  `SERVICE_STARTING`/`SERVICE_READY` events, and touches
  `/run/config-rendered`.
- `backend_readiness_probe.sh` recreates `/run/readiness`, polls systemd
  service states (`systemctl is-active`) and local TCP ports (`22`, `8080`,
  `4822`, `3389`, `5901`), executes
  `/google/scripts/layer_readiness_probe.sh`, writes status files under
  `/run/readiness/{ssh,http,rdp,vnc,all}`, and emits `BACKEND_PROBE_STARTING`
  and `BACKEND_READY` log events.
