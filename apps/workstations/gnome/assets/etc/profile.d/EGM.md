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

# GNOME Profile Scripts (`profile.d`)

## Overview

Shell profile script (`google-bin.sh`) placed in `/etc/profile.d/` for the GNOME
workstation layer that appends `/google/bin` to `PATH` for interactive shells if
it is not already present.

## Interface

- `google-bin.sh`: Shell script sourced via `/etc/profile.d/`.
- `PATH`: Environment variable read and updated.

## Invariants

- `/google/bin` is appended to `PATH` only if `:$PATH:` does not already
  contain `:/google/bin:`, preventing duplicate path entries across repeated
  sourcing.

## Side Effects

- Mutates the current shell's `PATH` variable by appending `:/google/bin` when
  `/google/bin` is absent from `PATH`.
