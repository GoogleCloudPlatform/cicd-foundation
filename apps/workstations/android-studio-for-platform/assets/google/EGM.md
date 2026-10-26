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

# ASfP Google Assets (`google`)

## Overview

Houses Google-specific runtime and build automation scripts under `/google` for
the Android Studio for Platform (`ASfP`) workstation image.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides AOSP and AAOS
  (`VCAR`) repository sync/build scripts, Cuttlefish Virtual Device (`CVD`)
  lifecycle scripts, and pre-snapshot credential cleanup utilities.

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): `build_aosp.sh`, `build_vcar.sh`,
  `start_vcar_cvd.sh`, `stop_vcar_cvd.sh`, and `cleanup_for_snapshot.sh`.

## Invariants

- AOSP build scripts drop root privileges when `EUID == 0` and require
  `/google/scripts/common.sh` for structured event logging.

## Side Effects

- Syncs and compiles AOSP/AAOS source trees in `$HOME`, manages background
  Cuttlefish emulator processes, and deletes local user credentials during
  snapshot preparation.
