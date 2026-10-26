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

# Open-Source Scripts CLI Entry Points (`persona-oss/scripts/cmd`)

## Overview

Groups command-line binary entry points for the `persona-oss` skill's Go
tooling.

## Interface

- [`uv_lock_scrubber`](./uv_lock_scrubber/EGM.md): CLI binary entry point
  (`package main`) that inspects and scrubs non-public package registry URLs in
  `uv.lock` files back to canonical public PyPI URLs.

## Subdirectories & Boundaries

- [`uv_lock_scrubber`](./uv_lock_scrubber/EGM.md): Parses CLI flags
  (`-api-base`, `-check`), resolves target `uv.lock` files, and invokes the
  `uvlock.Scrubber` engine.

## Invariants

- All CLI tools under `cmd/` parse flags via `flag.Parse()` (supporting the `--`
  argument separator required by pre-commit) and exit with status code `1` when
  check violations or in-place file modifications occur.

## Side Effects

- Delegates filesystem traversal, PyPI metadata resolution, in-place `uv.lock`
  rewriting, and localized stdout/stderr reporting to
  [`uv_lock_scrubber`](./uv_lock_scrubber/EGM.md).
