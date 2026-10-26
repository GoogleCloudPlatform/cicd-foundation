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

# `uv_lock_scrubber` CLI (`cmd/uv_lock_scrubber`)

## Overview

Provides the CLI entry point (`package main`) for the `uv_lock_scrubber`
pre-commit hook, which verifies that `uv.lock` files reference only canonical
public PyPI URLs and automatically rewrites private mirror URLs via upstream
PyPI JSON metadata lookup.

## Interface

- `main()`: CLI entry point that initializes 6-language UN localization, parses
  command-line flags via `flag.Parse()`, and executes `run()`.
- CLI Flags:
  - `-api-base` (`string`): Upstream PyPI JSON API base URL (default:
    `uvlock.DefaultPyPIAPIBase`, `"https://pypi.org/pypi"`).
  - `-check` (`bool`): Read-only verification mode; reports non-public URLs and
    exits non-zero without modifying files on disk (default: `false`).
- Positional CLI Arguments (`flag.Args()`): Optional file paths; only arguments
  whose basename is `uv.lock` are processed. When omitted, walks the current
  working directory recursively for `uv.lock` files.

## Invariants

- `flag.Parse()` is always used so `--` cleanly separates CLI flags from file
  paths supplied by `pre-commit`.
- Positional arguments whose `filepath.Base(arg)` is not `"uv.lock"` are
  ignored; when no arguments are supplied, recursive directory traversal skips
  `.git`, `.terraform`, `.venv`, `build`, `dist`, `node_modules`, and `tmp`
  (`skipDirs`, maintained via go/keep-sorted).
- If zero `uv.lock` targets match, `run()` returns `nil` without output.
- In `-check` mode, any detected non-public URL increments `taintedFiles` and
  returns a localized error without modifying disk files.
- In autofix mode (`-check=false`), rewriting one or more lockfiles prints
  per-file and summary messages and returns `"files modified"` so `main()` exits
  with status code `1` per standard `pre-commit` autofix semantics; a subsequent
  pass on clean lockfiles exits `0` offline.

## Side Effects

- Initializes global localization state via `i18n.Init("", "en",
locales.Content)`.
- Reads working directory metadata (`os.Getwd`, `filepath.WalkDir`) when no
  positional file arguments are given.
- Delegates HTTPS PyPI metadata lookups and in-place `uv.lock` rewrites to
  `uvlock.Scrubber.ProcessFile`.
- Writes localized progress and summary messages to `os.Stdout`, diagnostic
  errors to `os.Stderr`, and terminates via `os.Exit(1)` on error or file
  modification.
