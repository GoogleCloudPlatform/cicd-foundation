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

# assets

## Overview

Root filesystem overlay directory (`COPY assets/ /`) for the `build-runner`
container image. It organizes modular build hooks (`/build-hooks.d`), runner
configuration scripts and Python environment manifests (`/google`), and custom
CLI binaries (`/usr/local/bin`).

## Subdirectories & Boundaries

- `build-hooks.d`: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Modular build hook scripts (`01_install_devcontainers_cli.sh`) executed
  during image build to install `@devcontainers/cli`.
- `google`: [`./google/EGM.md`](./google/EGM.md) - System Python dependency
  manifest (`pyproject.toml`) and runner provisioning scripts
  (`scripts/build/configure_runner.sh`).
- `usr`: [`./usr/EGM.md`](./usr/EGM.md) - User-local binaries
  (`usr/local/bin/build_devcontainer`) for building and pushing devcontainer
  images.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `01_install_devcontainers_cli.sh` (`DEVCONTAINER_CLI_VERSION`).
- [`./google/EGM.md`](./google/EGM.md): `/google/pyproject.toml` and
  `/google/scripts/build/configure_runner.sh` (`EXTRA_PKGS`).
- [`./usr/EGM.md`](./usr/EGM.md): `/usr/local/bin/build_devcontainer`.

## Invariants

- Directory structure directly mirrors target absolute paths under `/` inside
  the `build-runner` container image.
- `/google/scripts/build/configure_runner.sh` orchestrates permissions and
  execution of `/build-hooks.d/*.sh` and `/usr/local/bin/*`.

## Side Effects

- Copying `assets/` into `/` populates `/build-hooks.d`, `/google`, and
  `/usr/local/bin` inside the container image prior to running
  `configure_runner.sh`.
