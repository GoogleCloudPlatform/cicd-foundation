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

# Update Preflight Skill (`update-preflight`)

## Overview

Agent skill (`SKILL.md`) and automation scripts for testing, building, and
hot-patching the `preflight-web` frontend onto a running Cloud Workstation
without rebuilding the container image.

## Subdirectories & Boundaries

- **Skill Specification**: [`./SKILL.md`](./SKILL.md) - Defines the
  `update-preflight` agent skill workflow and usage instructions.
- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides
  `test_and_hotpatch.sh` and `hotpatch_frontend.sh` for running Vitest suites
  and streaming `dist/` artifacts over SSH to `/var/www/html/`.

## Interface

- [`./SKILL.md`](./SKILL.md): Agent skill definition for `update-preflight`.
- [`./scripts/EGM.md`](./scripts/EGM.md): `hotpatch_frontend.sh` and
  `test_and_hotpatch.sh`.

## Invariants

- Hot-patching requires a running Cloud Workstation specified via `CWS_NAME`
  and passing frontend unit tests when invoked via `test_and_hotpatch.sh`.

## Side Effects

- Executes local `npm test` and `npm run build` in
  `apps/workstations/preflight-web` and updates `/var/www/html/` and
  `/run/config-rendered` on the remote workstation via `gcloud workstations
ssh`.
