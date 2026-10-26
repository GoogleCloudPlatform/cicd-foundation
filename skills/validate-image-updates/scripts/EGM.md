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

# Image Validation Scripts (`validate-image-updates/scripts`)

## Overview

Provides test orchestration scripts that execute local unit/linter pre-commit
suites and live Cloud Workstation Bats integration test suites.

## Interface

- `run_all_tests.sh [env_file]`: Primary entrypoint script (`main "$@"`) that
  sequentially executes sibling scripts `run_local_tests.sh` and
  `run_integration_tests.sh "$@"`.
- `run_local_tests.sh`: Entrypoint script (`main "$@"`) that sources
  `../../common.sh` and runs ten pre-commit test hooks (`bats-bin`,
  `bats-skills`, `pytest-skills`, `pytest-pipelines`, `go-test-persona`,
  `bats-preflight`, `bats-preflight-web`, `npm-install-preflight`, `vitest`,
  `bats-images`) across all files.
- `run_integration_tests.sh [env_file]`: Entrypoint script (`main "$@"`) that
  sources `../../common.sh` and `ENV_FILE` (`${1:-${REPO_ROOT}/.env}`), then
  executes Bats integration test suites under
  `${REPO_ROOT}/apps/workstations/*/tests/integration/` and
  `${REPO_ROOT}/apps/workstations/preflight/tests/integration/`.

## Invariants

- All scripts enforce strict Bash execution flags (`set -euo pipefail`) and
  resolve sibling and parent paths relative to `BASH_SOURCE[0]`.
- `run_all_tests.sh` strictly runs `run_local_tests.sh` before
  `run_integration_tests.sh`, halting before integration tests if any local
  test hook fails.
- `run_local_tests.sh` requires `pre-commit` in `PATH` or executable at
  `$HOME/.local/bin/pre-commit`, terminating via `error` if neither is found.
- `run_integration_tests.sh` exits with status `0` and logs a warning if
  `ENV_FILE` does not exist.
- When `ENV_FILE` exists, `run_integration_tests.sh` requires the `bats` CLI
  in `PATH` (terminating via `error` if missing), always runs integration
  tests for the `gnome` layer and `preflight` module, and only runs other
  image layer integration tests if the layer basename matches a substring of
  `EXTRA_BINARIES` or `CWS_CONFIG`.

## Side Effects

- Sources `../../common.sh` (in `run_local_tests.sh` and
  `run_integration_tests.sh`) and exports/sources `ENV_FILE` (in
  `run_integration_tests.sh`) into the shell environment.
- Changes the working directory to `${REPO_ROOT}` in `run_local_tests.sh`.
- Executes `pre-commit run <hook> --all-files` for unit tests, linters, and
  frontend checks.
- Executes `bats` integration test suites targeting a live Cloud Workstation
  instance configured by `ENV_FILE`.
- Emits formatted log, warning, and error messages via `log`, `warn`, and
  `error` functions from `common.sh`.
