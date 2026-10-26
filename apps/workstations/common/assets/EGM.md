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

# Common Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `common` base Cloud Workstation
layer, containing build-time tool installers (`build-hooks.d`), Docker and
systemd configuration and DinD startup hooks (`etc`), and the core
`/google/scripts` runtime and build framework (`google`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Installs Antigravity CLI/SDK, Google Agent Development Kit (`ADK`), gVisor
  (`runsc`), and the Devcontainers CLI (`@devcontainers/cli`).
- **System Configuration & Startup**: [`./etc/EGM.md`](./etc/EGM.md) -
  Configures Docker-in-Docker (`DinD`) kernel mounts, loopback devices, cgroup
  v2 nesting, and NVIDIA CDI at boot via `000_configure-docker.sh`.
- **Google Scripts**: [`./google/EGM.md`](./google/EGM.md) - Provides
  `/google/scripts` container entrypoint orchestration, `nftables` traffic
  control, persistent `machine-id` setup, `user_setup.sh`, `common.sh`, and
  `build/configure_workstation.sh`.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `04_install_antigravity.sh`, `05_install_adk.sh`, `06_install_gvisor.sh`,
  and `07_install_devcontainers.sh`.
- [`./etc/EGM.md`](./etc/EGM.md): `000_configure-docker.sh`.
- [`./google/EGM.md`](./google/EGM.md): `common.sh`, `entrypoint.sh`,
  `start_systemd.sh`, `traffic_control.sh`, `machine_id_setup.sh`,
  `cloud_logging_setup.sh`, `user_setup.sh`, `load_cached_images.sh`,
  `build/configure_workstation.sh`, and `build/install_functions.sh`.

## Invariants

- Enforces `nftables` ingress traffic blocking during initialization,
  deterministic `machine-id` persistence, and standardized permission
  normalization across `/google/scripts`, `/etc/workstation-startup.d`, and
  `/usr/local/bin`.

## Side Effects

- Installs core CLI/SDK toolchains, configures the DinD and systemd runtime
  environment, and transitions container PID 1 to `/sbin/init`.
