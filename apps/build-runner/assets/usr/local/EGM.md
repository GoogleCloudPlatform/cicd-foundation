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

# local

## Overview

Intermediate filesystem overlay directory mapping to `/usr/local` inside the
`build-runner` container image, housing custom CLI executables under `bin/`.

## Subdirectories & Boundaries

- `bin`: [`./bin/EGM.md`](./bin/EGM.md) - Provides the `build_devcontainer`
  CLI utility script for building and pushing Development Container images to
  Artifact Registry.

## Interface

- [`./bin/EGM.md`](./bin/EGM.md): Exposes `build_devcontainer <image_tag>
[workspace_folder]`.

## Invariants

- All files packaged under `/usr/local/bin/*` are granted executable
  permissions (`chmod +x`) by `/google/scripts/build/configure_runner.sh`
  during image construction.

## Side Effects

- Propagates CLI execution side effects (Docker Buildx builder management,
  `devcontainer build`, and `docker push`) defined in
  [`./bin/EGM.md`](./bin/EGM.md).
