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

# Repository CLI Utilities (`bin`)

## Overview

Shell utility scripts supporting local application development, environment
manifest and dependency generation, local service execution, and Skaffold-based
testing and Cloud Run deployment. `common.sh` provides shared option-parsing,
environment-loading, and manifest/dependency generation helpers sourced by
`cloudrun.sh`, `generate.sh`, `run.sh`, and `test.sh`.

## Interface

- `common.sh`:
  - `getOpts [-h|--help] [-d|--directory <dir>] [-a|--app <app>]` (sets `APP`,
    `ROOT_DIR`, and `OPT_SHIFT`)
  - `checkDependencies <cmd...>`
  - `resolveRepoRoot` (resolves canonical `REPO_ROOT` from `BASH_SOURCE[0]` or
    `$0`)
  - `getRootDir` (sets canonical `ROOT_DIR` and `SKAFFOLD_FILE`)
  - `readEnv <env_file>`
  - `readEnvs <env...>`
  - `generateEnvManifests [env...]`
  - `generateRequirementsTxt`
  - `generate [env...]`
- `cloudrun.sh [-a|--app <app>] [-d|--directory <dir>] [-h|--help] <dev|run|iam|delete>`:
  Functions `usage`, `getCmd`, `checkEnvs`, `cloudrun`, `applyIAM`.
- `generate.sh [-a|--all] [-h|--help]`: Functions `usage`, `apply`.
- `run.sh [-a|--app <app>] [-d|--directory <dir>] [-h|--help] [service]`:
  Functions `usage`, `startService`, `run`.
- `test.sh [-a|--app <app>] [-d|--directory <dir>] [-h|--help]`: Functions
  `usage`, `runTests`.
- `tests/` (`test_helper.bash`, `test_bin_scripts.bats`): Bats unit test suite
  covering `common.sh`, `cloudrun.sh`, `generate.sh`, `run.sh`, and `test.sh`.

## Invariants

- Scripts sourcing `common.sh` require either `ROOT_DIR` to be set, a
  `skaffold.yaml` file in the current working directory, or `APP` to be set
  (exiting with code `3` otherwise).
- `checkDependencies` requires specified binaries (`envsubst`, `skaffold`) to
  be present in `PATH` or exits with code `1`.
- `cloudrun.sh` requires `PROJECT_ID` and `REGION` environment variables to be
  non-empty after loading `dev` environment files or exits with code `4`.
- `cloudrun.sh` only accepts commands `dev`, `run`, `delete`, or `iam`
  (exiting with code `2` otherwise).
- `run.sh` requires a `Procfile` in `$ROOT_DIR/src/<service>` to determine the
  startup `PROCFILE_CMD`, exiting with code `1` if `PROCFILE_CMD` remains empty
  or if no matching service is found.

## Side Effects

- `common.sh` (`readEnv`/`readEnvs`/`generateEnvManifests`): Exports
  environment variables into the shell session via `set -a` from `$(dirname
"$ROOT_DIR")/.env`, `$ROOT_DIR/envs/base/.env`, and
  `$ROOT_DIR/envs/$ENV/.env`, plus `ENV` and `TEAM_PREFIX`.
- `common.sh` (`generateEnvManifests`): Writes rendered manifest files to
  `$ROOT_DIR/envs/$ENV/<template_basename>` from `$ROOT_DIR/envs/base/*.tmpl`
  using `envsubst`.
- `common.sh` (`generateRequirementsTxt`): Writes
  `$ROOT_DIR/src/*/requirements.txt` by running `poetry export` or `uv export`
  in each service directory.
- `cloudrun.sh`: Deploys or deletes Cloud Run services via `skaffold
<dev|run|delete>` and mutates Cloud Run IAM policies via `gcloud run services
add-iam-policy-binding` to grant `roles/run.invoker` to `allUsers` for
  services listed in `PUBLIC_SERVICES` (when command is `run` or `iam`).
- `run.sh`: Installs Python dependencies locally via `poetry install`, `uv
sync`, or `pip install -q -r requirements.txt` in `$ROOT_DIR/src/<service>`
  and executes the `Procfile` command via `poetry run sh -c`, `uv run sh -c`,
  or `sh -c`.
- `test.sh`: Creates a temporary JSON file via `mktemp --suffix=.json`
  (cleaned up on `EXIT`) and executes `skaffold build` and `skaffold test`.

## Verification

- Unit Tests: `bats -r bin/tests/`
