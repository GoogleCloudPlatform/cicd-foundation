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

# Setup Workstation Commands (`cmd`)

## Overview

Contains command-line entrypoints for the `setup-workstation` Go module.

## Subdirectories & Boundaries

- **Setup Workstation CLI**:
  [`./setup-workstation/EGM.md`](./setup-workstation/EGM.md) - Parses CLI
  flags and environment defaults and dispatches execution to `internal/setup`.

## Interface

- [`./setup-workstation/EGM.md`](./setup-workstation/EGM.md):
  `setup-workstation` binary entrypoint (`main`, `runCLI`, `parseFlags`).

## Invariants

- CLI flags (`--config`, `--directory`, `--needs-setup`, `--reset`) fall back
  to `SETUP_CONFIG` (`/google/etc/setup-workstation.yaml`) and
  `SETUP_DIRECTORY` (`/google/etc/setup-workstation.d`).

## Side Effects

- Parses process flags, handles OS interrupt signals, and invokes
  `internal/setup` routines.
