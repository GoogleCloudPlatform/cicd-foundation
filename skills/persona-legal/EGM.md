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

# Legal Expert Persona (`persona-legal`)

## Overview

Defines the Legal Expert (`persona-legal`) agent skill and bundles automated
tooling for enforcing SPDX license headers, copyright year accuracy, and
Software Bill of Materials (SBOM) license asset synchronization.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative skill definition and license
  compliance workflow for the Legal Expert persona.
- [`scripts`](./scripts/EGM.md): Automation scripts (`sbom_helper.py`,
  `sync_license_assets.sh`) and the Go `license_enforcer` CLI tool
  (`./scripts/cmd/license_enforcer/EGM.md`).

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): Houses SBOM license synchronization utilities
  and the `license_enforcer` Go module.

## Invariants

- All repository source files must carry valid SPDX license headers and
  up-to-date copyright years as enforced by [`scripts`](./scripts/EGM.md).
- Every third-party dependency bundled in the Preflight dashboard must be
  attributed in `apps/workstations/preflight-web/public/sbom.json` with
  synchronized local license text.

## Side Effects

- Executing the skill's tooling in [`scripts`](./scripts/EGM.md) modifies
  source file license headers in-place and downloads remote license texts into
  `apps/workstations/preflight-web/public/licenses/`.
