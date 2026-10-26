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

# Common Cloud Workstation Layer (`common`)

## Overview

Foundational base layer for all custom Google Cloud Workstation images. Provides
the systemd PID 1 boot lifecycle, `nftables` traffic gating, Docker-in-Docker
(`DinD`) and optional gVisor/Devcontainers support, Antigravity CLI/SDK and
Google ADK installations, centralized build orchestration
(`configure_workstation.sh`), and the `setup-workstation` interactive user
onboarding CLI tool.

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains `/build-hooks.d` tool installers,
  `/etc/workstation-startup.d/000_configure-docker.sh` DinD setup, and
  `/google/scripts` runtime/build utilities.
- **Workstation Tools**: [`./tools/EGM.md`](./tools/EGM.md) - Contains the
  `setup-workstation` Go CLI utility for interactive Chezmoi-backed dotfile
  personalization.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): `/google/scripts/common.sh`,
  `/google/scripts/entrypoint.sh`,
  `/google/scripts/build/configure_workstation.sh`,
  `/google/scripts/build/install_functions.sh`, and `/build-hooks.d` /
  `/etc/workstation-startup.d` hooks.
- [`./tools/EGM.md`](./tools/EGM.md): `setup-workstation` CLI binary and
  `internal/setup` Go package.

## Invariants

- All downstream workstation layers inherit `/google/scripts/common.sh` and
  execute `/google/scripts/build/configure_workstation.sh` during image build.
- External ingress traffic is blocked via `nftables` until startup readiness
  completes, and `/home/.workstation/machine-id` persists across restarts.

## Side Effects

- Compiles and installs `/google/bin/setup-workstation`, installs foundational
  APT/CLI/SDK packages, initializes DinD and systemd services, and manages
  user home/runtime directories at boot.
