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

# Antigravity 2.0 Build Hooks (`build-hooks.d`)

## Overview

Build-time hook script (`01_install_antigravity2.sh`) that downloads the
Antigravity 2.0 Linux x64 tarball from Google Cloud Storage, validates its
SHA-256 checksum using centralized install utilities, extracts the archive into
`/opt`, and removes the temporary tarball.

## Interface

- `01_install_antigravity2.sh`: Executed by
  `/google/scripts/build/configure_workstation.sh` via `run_hooks`.
- Required environment variables: `ANTIGRAVITY2_VERSION` (interpolated into
  `DOWNLOAD_URL`), `ANTIGRAVITY2_SHA256` (passed to `download_and_validate`),
  and `CURL_OPTS`.
- Sourced library: `/google/scripts/build/install_functions.sh`
  (`download_and_validate`).
- Script variables defined: `DOWNLOAD_URL`, `TARBALL_NAME`
  (`"Antigravity.tar.gz"`), `EXTRACT_DIR` (`"/opt"`), `BINARY_PATH`
  (`"/opt/Antigravity-x64/antigravity"`), `INSTALL_NAME`
  (`"antigravity-2.0"`), and `ALIAS_NAME` (`"antigravity"`).

## Invariants

- Executes under strict shell mode (`set -euo pipefail`);
  `ANTIGRAVITY2_VERSION`, `ANTIGRAVITY2_SHA256`, and `CURL_OPTS` must be set
  in the environment or execution aborts immediately.
- `/google/scripts/build/install_functions.sh` must be present at build time
  and provide `download_and_validate`.
- The downloaded `Antigravity.tar.gz` archive must pass SHA-256 verification
  against `ANTIGRAVITY2_SHA256` before extraction proceeds (unless
  `ANTIGRAVITY2_SHA256` is set to `NOCHECK`).
- The temporary tarball `Antigravity.tar.gz` is deleted after extraction into
  `/opt`.

## Side Effects

- Sources `/google/scripts/build/install_functions.sh`.
- Downloads
  `https://storage.googleapis.com/antigravity-public/antigravity-hub/${ANTIGRAVITY2_VERSION}/linux-x64/Antigravity.tar.gz`
  to `Antigravity.tar.gz` via `curl`.
- Creates `/opt` (if missing) and extracts `Antigravity.tar.gz` into `/opt`
  (populating `/opt/Antigravity-x64/antigravity`).
- Removes `Antigravity.tar.gz` from the current working directory.
