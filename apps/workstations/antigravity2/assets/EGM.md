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

# Antigravity 2.0 Layer Assets (`assets`)

## Overview

Root filesystem overlay (`assets/`) for the `antigravity2` Cloud Workstation
layer, containing the Antigravity 2.0 tarball installer (`build-hooks.d`), the
`/usr/local/bin/antigravity` launch wrapper (`usr/local/bin`), and desktop entry
metadata (`usr/share/applications/antigravity.desktop`).

## Subdirectories & Boundaries

- **Build Hooks**: [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md) -
  Downloads, verifies (`ANTIGRAVITY2_SHA256`), and extracts the Antigravity
  2.0 release tarball into `/opt/Antigravity-x64`.
- **User Binaries & Desktop Assets** (`./usr`): Provides
  `usr/local/bin/antigravity` (headless GPU-bypass and keyring launch wrapper
  invoking `/opt/Antigravity-x64/antigravity`) and
  `usr/share/applications/antigravity.desktop`.

## Interface

- [`./build-hooks.d/EGM.md`](./build-hooks.d/EGM.md):
  `01_install_antigravity2.sh` (`ANTIGRAVITY2_VERSION`, `ANTIGRAVITY2_SHA256`,
  `CURL_OPTS`).
- `usr/local/bin/antigravity`: Antigravity 2.0 launch wrapper.
- `usr/share/applications/antigravity.desktop`: XDG desktop entry.

## Invariants

- Enforces SHA-256 verification on `Antigravity.tar.gz` prior to unpacking
  into `/opt`.

## Side Effects

- Installs `/opt/Antigravity-x64/antigravity`, `/usr/local/bin/antigravity`,
  and `/usr/share/applications/antigravity.desktop` into the container
  filesystem.
