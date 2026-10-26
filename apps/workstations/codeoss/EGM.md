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

# Code-OSS Cloud Workstation Layer (`codeoss`)

## Overview

Rebases the predefined Google Cloud Workstations Code-OSS container image (`us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest`) onto the `preflight` and `common` foundation layers (`COPY --from=base-provider /export/ /`), replacing the upstream startup script with systemd-managed `code-oss.service` on port `8080` and enabling gVisor (`runsc`) and the DevContainer CLI.

## Interface

- `Dockerfile`:
  - Build arguments and environment variables: `BASE_IMAGE`, `BACKEND_PROXY_PATH="/"` , `PORT=80`, `DEFAULT_CLIENT_PROTOCOL="HTTP"`, `DEFAULT_REDIRECT_PATH="/"`, `SUPPORTED_PROTOCOLS="HTTP,SSH"`, `INSTALL_GVISOR=true`, `INSTALL_DEVCONTAINERS=true`, `EXTRA_PKGS`, `PURGE_PKGS`, `HOLD_PKGS`.
  - Entrypoint: `["/google/scripts/entrypoint.sh"]`.
- `assets/etc/systemd/system/code-oss.service`: Systemd unit running `/opt/code-oss/bin/codeoss-cloudworkstations --port=8080 --host=0.0.0.0` as `user:user`.
- `assets/etc/systemd/system/backend-readiness.service.d/10-codeoss.conf`: Sets `Environment="BACKEND_WAIT_PORTS=8080"`.
- `skaffold.yaml`: Skaffold `v4beta11` configuration building the `codeoss` image artifact with `BASE_IMAGE` wired to `preflight`.

## Invariants

- Removes `/etc/workstation-startup.d/110_start-code-oss.sh` during image build so Code-OSS is exclusively managed by systemd (`code-oss.service`).
- `backend-readiness.service` blocks `/readyz` (`X-App-Status: STARTING`) until TCP port `8080` (`BACKEND_WAIT_PORTS=8080`) accepts connections.

## Side Effects

- Purges and holds `apache2*` and `php*` packages, installs `EXTRA_PKGS` (`apt-transport-artifact-registry`, `curl`, `gettext-base`, `nginx`, `systemd`, `unzip`, `nodejs`, `openssh-server`), gVisor, and DevContainer CLI via `/google/scripts/build/configure_workstation.sh`, and starts `code-oss.service` on port `8080` at container boot.
