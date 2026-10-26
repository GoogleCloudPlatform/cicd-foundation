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

# Legal Persona Scripts (`persona-legal/scripts`)

## Overview

Provides Software Bill of Materials (SBOM) license synchronization scripts and
the Go-based `license_enforcer` CLI tool for verifying copyright headers and
SPDX license compliance across the repository.

## Interface

- `sbom_helper.py`: Python CLI (`get_license_mappings(sbom_path_str: str) ->
None`) that parses a JSON SBOM file (`licenses` dictionary) and prints
  space-separated `<lid> <url> <local_text>` tuples to stdout for entries
  defining both `url` and `local_text`.
- `sync_license_assets.sh`: Bash entrypoint script (`main "$@"`) that sources
  `../../common.sh`, invokes `sbom_helper.py` on
  `${REPO_ROOT}/apps/workstations/preflight-web/public/sbom.json`, and
  downloads remote license texts into
  `${REPO_ROOT}/apps/workstations/preflight-web/public/${local_text}`.
- [`cmd`](./cmd/EGM.md): Subdirectory housing the
  [`license_enforcer`](./cmd/license_enforcer/EGM.md) CLI binary entry point.
- [`internal`](./internal/EGM.md): Subdirectory housing internal Go packages
  for [`i18n`](./internal/i18n/EGM.md),
  [`licensing`](./internal/licensing/EGM.md), and
  [`locales`](./internal/locales/EGM.md).

## Invariants

- `sbom_helper.py` requires at least one CLI argument (`len(sys.argv) >= 2`)
  and that `<sbom_json_path>` exists as a valid UTF-8 JSON file; otherwise it
  writes an error message to `sys.stderr` and terminates with exit code `1`.
- `sbom_helper.py` only emits license mappings for entries in
  `data.get("licenses", {})` where both `url` and `local_text` are non-empty.
- `sync_license_assets.sh` executes under `set -euo pipefail` and requires
  `${REPO_ROOT}/apps/workstations/preflight-web/public/sbom.json` to exist
  (calling `error` from `common.sh` if missing).
- `sync_license_assets.sh` explicitly skips downloading the `Unsplash` license
  ID (`lid == "Unsplash"`) to preserve the existing custom license text.

## Side Effects

- `sbom_helper.py` reads the SBOM JSON file from disk, writes `<lid> <url>
<local_text>` lines to stdout, writes error diagnostics to stderr, and calls
  `sys.exit(1)` on errors.
- `sync_license_assets.sh` sources `../../common.sh`, creates
  `${REPO_ROOT}/apps/workstations/preflight-web/public/licenses` via `mkdir
-p`, creates and removes a temporary file via `mktemp` / `rm -f`, executes
  `python3 sbom_helper.py`, and performs HTTP GET requests via `curl -fsSL` to
  write license files under
  `${REPO_ROOT}/apps/workstations/preflight-web/public/${local_text}`.
