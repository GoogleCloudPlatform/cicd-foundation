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

# Update Preflight Scripts (`scripts`)

## Overview

Shell scripts for testing, building, and hot-patching the `preflight-web`
frontend assets onto a live Cloud Workstation.

## Interface

- `hotpatch_frontend.sh [--wipe] [GOOGLE_CLOUD_PROJECT] [CWS_REGION]`: Builds
  `preflight-web` and deploys `dist/` to a live Cloud Workstation (`functions`:
  `find_repo_root`, `main`; `env`: `CWS_NAME`, `GOOGLE_CLOUD_PROJECT`,
  `CWS_REGION`, `CWS_CLUSTER`, `CWS_CONFIG`).
- `test_and_hotpatch.sh`: Runs the `preflight-web` test suite before executing
  `hotpatch_frontend.sh` (`functions`: `find_repo_root`, `main`).

## Invariants

- Both scripts execute with strict bash error handling (`set -euo pipefail`)
  and require locating `skills/common.sh` in a parent directory via
  `find_repo_root`.
- `hotpatch_frontend.sh` requires the `CWS_NAME` environment variable to be
  non-empty, aborting via `error()` if unset.
- `test_and_hotpatch.sh` gates deployment on the Vitest suite (`npm test` in
  `apps/workstations/preflight-web`) succeeding before invoking
  `hotpatch_frontend.sh`.
- Remote files in `/var/www/html/` on the target workstation are always
  normalized to `root:root` ownership with mode `755` for directories and
  `644` for files.

## Side Effects

- `test_and_hotpatch.sh` runs `npm test --prefix
<REPO_ROOT>/apps/workstations/preflight-web` locally.
- `hotpatch_frontend.sh` runs `npm run build --prefix
<REPO_ROOT>/apps/workstations/preflight-web` locally to generate Vite build
  artifacts in `dist/`.
- `hotpatch_frontend.sh` connects to the target workstation via `gcloud
workstations ssh` and, under `sudo`, optionally removes `/var/www/html/*`
  (when `--wipe` is passed), extracts the `dist/` tarball into
  `/var/www/html/`, sets ownership and permissions, removes
  `/run/config-rendered`, and runs `/google/scripts/config_rendering.sh`.
