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

# Remote Desktop Profile Scripts (`profile.d`)

## Overview

Shell profile script (`google-bin.sh`) for `/etc/profile.d` that idempotently
appends `/google/bin` to `PATH` for interactive/login shells.

## Interface

- `google-bin.sh`: Sourced via `/etc/profile.d/`.
- `PATH`: Environment variable read and updated.

## Invariants

- `/google/bin` is only appended to `PATH` if `:$PATH:` does not already
  contain `:/google/bin:` (idempotent).

## Side Effects

- Mutates the `PATH` environment variable in the sourcing shell environment by
  appending `:/google/bin` when not already present.
