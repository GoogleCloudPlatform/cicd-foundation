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

# Validate Image Updates Skill (`validate-image-updates`)

## Overview

Defines the mandatory 6-step sequential validation workflow for Cloud
Workstation image builds and codebase updates, paired with automated test runner
scripts for local pre-commit and live instance integration testing.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative 6-step validation workflow
  specification (`Stop Workstation`, `Run Local Tests`, `Monitor Build`,
  `Start Workstation`, `Run Integration Tests`, `Persona Reviews`).
- [`scripts`](./scripts/EGM.md): Test runner scripts (`run_all_tests.sh`,
  `run_local_tests.sh`, `run_integration_tests.sh`) that execute local
  pre-commit test hooks and remote Bats integration suites.
- `tests/` (`bats_common.bash`, `bats_integration.bash`, `test_helper.bash`,
  `test_directory_structure.bats`): Shared Bats helper libraries
  (`skip_if_slow()`, `assert_all_scripts_executable()`, `setup_env()`,
  `run_ssh()`, `assert_app_autostarted()`, `assert_app_pinned()`,
  `find_repo_root()`) and repository structure validation tests.

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): Contains `run_all_tests.sh`,
  `run_local_tests.sh`, and `run_integration_tests.sh` for orchestrating unit,
  linter, frontend, and live workstation integration tests.
- `tests`: Shared Bats test helpers and directory structure test suites.

## Invariants

- Workstation instances must be in `STATE_STOPPED` prior to local validation
  and Cloud Build monitoring, and may only be started after the build reaches
  `SUCCESS`.
- Local test suites (`run_local_tests.sh`) must pass completely before
  integration test suites (`run_integration_tests.sh`) are executed.

## Side Effects

- Executing scripts in [`scripts`](./scripts/EGM.md) sources `../common.sh`
  and `.env`, runs `pre-commit` test hooks across the repository, and executes
  `bats` integration tests against the configured Cloud Workstation instance.
