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

# SWE Scripts CLI Entry Points (`persona-swe/scripts/cmd`)

## Overview

Groups command-line binary entry points for the `persona-swe` skill's Go
tooling.

## Interface

- [`link_checker`](./link_checker/EGM.md): CLI binary entry point (`package
main`) that scans Markdown files across the repository and reports broken
  relative file and image links.

## Subdirectories & Boundaries

- [`link_checker`](./link_checker/EGM.md): Parses CLI positional arguments
  (`flag.Args()`) and orchestrates bounded concurrent link checking across
  target Markdown files or the repository tree.

## Invariants

- All CLI tools under `cmd/` parse flags via `flag.Parse()` (supporting the
  `--` argument separator) and exit with status code `1` if broken relative
  links or filesystem traversal errors are encountered.

## Side Effects

- Delegates repository root discovery, directory walking, concurrent link
  checking, and stdout/stderr reporting to
  [`link_checker`](./link_checker/EGM.md).
