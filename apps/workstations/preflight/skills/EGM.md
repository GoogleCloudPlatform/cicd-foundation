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

# Preflight Skills (`skills`)

## Overview

Groups module-specific AI agent skills for the `preflight` Cloud Workstation
layer.

## Subdirectories & Boundaries

- **Update Preflight**:
  [`./update-preflight/EGM.md`](./update-preflight/EGM.md)
  ([`./update-preflight/SKILL.md`](./update-preflight/SKILL.md)) - Tests,
  builds, and hot-patches the `preflight-web` frontend directly onto a live
  Cloud Workstation.

## Interface

- [`./update-preflight/EGM.md`](./update-preflight/EGM.md): `update-preflight`
  skill and hot-patching scripts.

## Invariants

- All hot-patch deployments are gated on local `preflight-web` build and test
  completion and require an active target `CWS_NAME`.

## Side Effects

- Builds frontend artifacts locally and overwrites `/var/www/html/` on the
  remote workstation via SSH.
