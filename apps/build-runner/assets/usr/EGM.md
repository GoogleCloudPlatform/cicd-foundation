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

# usr

## Overview

Intermediate filesystem overlay directory mapping to `/usr` inside the
`build-runner` container image, containing local CLI binaries under `local/`.

## Subdirectories & Boundaries

- `local`: [`./local/EGM.md`](./local/EGM.md) - Houses `/usr/local/bin`
  utilities packaged into the `build-runner` image.

## Interface

- [`./local/EGM.md`](./local/EGM.md): Exposes
  `/usr/local/bin/build_devcontainer`.

## Invariants

- Preserves the standard `/usr/local/bin` filesystem hierarchy when `assets/`
  is merged into `/` during the Docker build.

## Side Effects

- Contributes `/usr/local/bin/build_devcontainer` to the container's default
  executable `PATH`.
