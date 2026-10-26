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

# scripts

## Overview

Groups build-time provisioning and configuration scripts mounted under
`/google/scripts` in the `build-runner` container image.

## Subdirectories & Boundaries

- `build`: [`./build/EGM.md`](./build/EGM.md) - Build-time runner
  configuration script (`configure_runner.sh`) that configures GCE package
  mirrors, installs optional APT and Python dependencies, sets executable
  permissions, runs `/build-hooks.d` scripts, and cleans APT caches.

## Interface

- [`./build/EGM.md`](./build/EGM.md): Exposes `configure_runner.sh` and the
  optional `EXTRA_PKGS` environment variable.

## Invariants

- Child build scripts execute under strict Bash error handling (`set -euo
pipefail`).

## Side Effects

- Delegates container filesystem and package mutations to scripts in
  [`./build/EGM.md`](./build/EGM.md).
