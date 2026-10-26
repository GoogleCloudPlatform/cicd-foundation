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

# Common Google Assets (`google`)

## Overview

Houses the foundational `/google/scripts` runtime boot orchestration, shared
logging/retry utilities, and build-time layer configuration framework for all
Cloud Workstations images.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides `common.sh`,
  `entrypoint.sh`, `start_systemd.sh`, `traffic_control.sh`,
  `machine_id_setup.sh`, `cloud_logging_setup.sh`, `user_setup.sh`,
  `load_cached_images.sh`, and `./scripts/build` (`configure_workstation.sh`,
  `install_functions.sh`).

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): Runtime boot scripts, `common.sh`
  shared library, and `build/configure_workstation.sh` build orchestrator.

## Invariants

- Blocks external network ingress via `nftables` during boot until readiness
  checks complete, persists `/home/.workstation/machine-id`, and enforces
  centralized build hook execution order (`build-hooks.d` -> APT ->
  `post-install-hooks.d`).

## Side Effects

- Initializes container boot state, mounts/configures systemd (`PID 1`),
  manages `nftables` rules, streams systemd journal logs to stdout, and
  installs/normalizes workstation layer packages and permissions.
