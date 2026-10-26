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

# Agent Skills Subsystem (`skills`)

## Overview

Contains the repository's specialized AI agent skills (adhering to the
`agentskills.io` specification), shared shell utilities (`common.sh`), and
persona-specific automation tooling (Go CLIs, Python helpers, and Bash scripts)
for managing, validating, and auditing the Cloud Workstations environment.

## Interface

- `common.sh`: Shared Bash library sourced by skill scripts:
  - `SCRIPT_COMMON_DIR` (shell variable): Absolute path to the `skills/`
    directory containing `common.sh`.
  - `REPO_ROOT` (exported environment variable): Absolute path to the
    repository root directory (`${SCRIPT_COMMON_DIR}/..`).
  - `BUILD_REGION` (exported environment variable): Build region, falling
    back to `${CWS_REGION:-}` if unset or empty.
  - `ARTIFACT_REGION` (exported environment variable): Artifact region,
    falling back to `${BUILD_REGION:-${CWS_REGION:-}}` if unset or empty.
  - `log(message...)`: Prints a blue-colored `HH:MM:SS` timestamped message
    to stdout.
  - `warn(message...)`: Prints a yellow-colored `[WARN]` message to stdout.
  - `error(message...)`: Prints a red-colored `[ERROR]` message to stderr
    and exits with status `1`.
- Skill Subdirectories:
  - [`deploy-workstations`](./deploy-workstations/SKILL.md): Interactive
    workflow skill that guides administrators through generating
    `infra/blueprints/workstations/terraform.tfvars` and running `terraform
plan`.
  - [`persona-agent-manager`](./persona-agent-manager/SKILL.md): Agent
    Manager persona skill governing skill lifecycle management, `AGENTS.md`
    enforcement, toil reduction, and `SKILL.md` metadata validation.
  - [`persona-legal`](./persona-legal/EGM.md): Legal Expert persona skill
    and automation tooling (`license_enforcer` Go CLI, `sbom_helper.py`,
    `sync_license_assets.sh`) for SPDX license enforcement and SBOM
    synchronization.
  - [`persona-oss`](./persona-oss/EGM.md): Open-Source Expert (OSS)
    persona skill and Go-based `uv_lock_scrubber` pre-commit CLI enforcing
    upstream-first contributions, public PyPI lockfile URL scrubbing, and
    secret scrubbing.
  - [`persona-privacy`](./persona-privacy/SKILL.md): Privacy Expert persona
    skill and review playbook
    (`./persona-privacy/references/privacy_review.md`) for auditing PII
    protection, ephemeral state (`tmpfs`), and privacy compliance.
  - [`persona-security`](./persona-security/EGM.md): Security Expert (SEC)
    persona skill and GPG keyring refresh script (`update_gpg_keys.sh`) for
    APT repository key validation and system hardening.
  - [`persona-sre`](./persona-sre/EGM.md): Site-Reliability Engineer (SRE)
    persona skill, troubleshooting playbook
    (`./persona-sre/references/troubleshooting.md`), and operational scripts
    (`manage_workstation.sh`, `monitor_build.sh`, `trigger_build.py`,
    `dbus_session_cmd.sh`).
  - [`persona-swe`](./persona-swe/EGM.md): Software Engineer (SWE) persona
    skill, coding style mandates, and Go-based Markdown relative link
    checker (`link_checker`).
  - [`persona-ux`](./persona-ux/SKILL.md): UX Specialist persona skill
    enforcing visual consistency, layout stability, accessibility, inclusive
    terminology, and 6-language UN i18n compliance.
  - [`validate-image-updates`](./validate-image-updates/EGM.md): Mandatory
    6-step image validation workflow skill and test runner scripts
    (`run_all_tests.sh`, `run_local_tests.sh`, `run_integration_tests.sh`).

## Subdirectories & Boundaries

- [`deploy-workstations`](./deploy-workstations/SKILL.md): Interactive
  Terraform configuration generator and `terraform plan` workflow for
  deploying the Cloud Workstations blueprint.
- [`persona-agent-manager`](./persona-agent-manager/SKILL.md): Manages agent
  skill lifecycle, orchestration rules, and `agentskills.io` frontmatter
  validation (`tests/validate_skill.bats`).
- [`persona-legal`](./persona-legal/EGM.md): Enforces SPDX license headers,
  copyright years, and SBOM license synchronization via
  [`persona-legal/scripts`](./persona-legal/scripts/EGM.md).
- [`persona-oss`](./persona-oss/EGM.md): Governs upstream contribution
  workflows and public repository release scrubbing (including canonical PyPI
  `uv.lock` verification) via [`persona-oss/scripts`](./persona-oss/scripts/EGM.md).
- [`persona-privacy`](./persona-privacy/SKILL.md): Governs data minimization,
  PII auditing, and ephemeral runtime storage verification.
- [`persona-security`](./persona-security/EGM.md): Governs system hardening,
  credential protection, and third-party APT GPG key synchronization via
  [`persona-security/scripts`](./persona-security/scripts/EGM.md).
- [`persona-sre`](./persona-sre/EGM.md): Governs Cloud Workstation lifecycle
  management, Cloud Build orchestration, and live D-Bus session debugging via
  [`persona-sre/scripts`](./persona-sre/scripts/EGM.md).
- [`persona-swe`](./persona-swe/EGM.md): Governs software engineering
  standards, language style guides, and Markdown relative link verification
  via [`persona-swe/scripts`](./persona-swe/scripts/EGM.md).
- [`persona-ux`](./persona-ux/SKILL.md): Governs desktop/dashboard UX
  stability, accessibility, and localization standards.
- [`validate-image-updates`](./validate-image-updates/EGM.md): Orchestrates
  sequential local pre-commit tests and live workstation integration tests via
  [`validate-image-updates/scripts`](./validate-image-updates/scripts/EGM.md).

## Invariants

- In `common.sh`, `REPO_ROOT` is always resolved relative to `BASH_SOURCE[0]`
  as the parent directory of `skills/`, and existing exported environment
  variables are never overwritten when loading `${REPO_ROOT}/.env`.
- In `common.sh`, `BUILD_REGION` defaults to `CWS_REGION` if unset/empty,
  `ARTIFACT_REGION` defaults to `BUILD_REGION` (and transitively `CWS_REGION`)
  if unset/empty, and calling `error()` unconditionally terminates the shell
  process with exit code `1`.
- Every skill directory must contain a `SKILL.md` file with YAML frontmatter
  starting on Line 1 defining `name`, `description`, and `license:
Apache-2.0`, and all paths declared in `allowed-tools` and
  `metadata.resources` must resolve to existing files in the repository.
- Go CLI utilities under
  [`persona-legal/scripts`](./persona-legal/scripts/EGM.md),
  [`persona-oss/scripts`](./persona-oss/scripts/EGM.md), and
  [`persona-swe/scripts`](./persona-swe/scripts/EGM.md) must use
  `flag.Parse()` to support the `--` separator in pre-commit hooks.

## Side Effects

- Sourcing `common.sh` reads `${REPO_ROOT}/.env` (if present), exports
  `REPO_ROOT`, `BUILD_REGION`, `ARTIFACT_REGION`, and unset `.env` variables
  into the current shell environment, and writes ANSI-colored log messages to
  stdout/stderr.
- Executing scripts across child skill packages mutates source file license
  headers, refreshes APT GPG keyrings and SBOM license texts, runs local
  pre-commit and remote Bats test suites, and manages Cloud Workstation
  instances and Cloud Builds via `gcloud`.
