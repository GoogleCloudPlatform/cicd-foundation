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

# google

## Overview

Defines the `/google` root asset tree copied into the `build-runner` container
image, containing the system Python environment specification (`pyproject.toml`)
and build-time provisioning scripts (`scripts/`).

## Subdirectories & Boundaries

- `scripts`: [`./scripts/EGM.md`](./scripts/EGM.md) - Build-time provisioning
  and runner configuration scripts under `/google/scripts`.

## Interface

- `pyproject.toml`: Python project manifest (`build-runner-env` v0.1.0,
  `requires-python = ">=3.11"`) declaring system-level dependency
  `google-antigravity==0.1.22`.
- [`./scripts/EGM.md`](./scripts/EGM.md): Build scripts
  (`configure_runner.sh`) that consume `/google/pyproject.toml`.

## Invariants

- Requires Python `>=3.11` for `build-runner-env` dependencies
  (`google-antigravity==0.1.22`).
- `pyproject.toml` is installed into the system Python environment by
  `scripts/build/configure_runner.sh` via `uv pip install --system
--break-system-packages -r /google/pyproject.toml` when
  `/opt/antigravity-sdk` is present.

## Side Effects

- Directs `uv` during image build to install `google-antigravity==0.1.22` into
  the container's system Python environment.
