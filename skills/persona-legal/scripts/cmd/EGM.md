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

# Legal Scripts CLI Entry Points (`persona-legal/scripts/cmd`)

## Overview

Groups command-line binary entry points for the `persona-legal` skill's Go
tooling.

## Interface

- [`license_enforcer`](./license_enforcer/EGM.md): CLI binary entry point
  (`package main`) that scans files and directories to enforce SPDX license
  headers and copyright year accuracy.

## Subdirectories & Boundaries

- [`license_enforcer`](./license_enforcer/EGM.md): Parses CLI flags
  (`-holder`, `-license`, `-acceptable-licenses`, `-exclude`, `-filter`,
  `-format`) and orchestrates bounded concurrent license enforcement across
  target paths.

## Invariants

- All CLI tools under `cmd/` parse flags via `flag.Parse()` (supporting the
  `--` argument separator) and exit with status code `1` when license
  violations or in-place modifications occur.

## Side Effects

- Delegates filesystem traversal, in-place license header rewriting, and
  localized stdout/stderr reporting to
  [`license_enforcer`](./license_enforcer/EGM.md).
