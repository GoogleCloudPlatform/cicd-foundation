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

# SWE Persona Scripts (`persona-swe/scripts`)

## Overview

Houses the Go module (`skills/persona-swe/scripts`) providing automated
engineering hygiene and documentation verification tooling, including the
`link_checker` CLI utility.

## Interface

- [`cmd`](./cmd/EGM.md): Subdirectory housing the
  [`link_checker`](./cmd/link_checker/EGM.md) CLI binary entry point.
- [`internal`](./internal/EGM.md): Subdirectory housing the internal
  [`linkchecker`](./internal/linkchecker/EGM.md) AST link validation package.

## Subdirectories & Boundaries

- [`cmd`](./cmd/EGM.md): CLI entry points (`cmd/link_checker`) for
  repository-wide or targeted Markdown relative link validation.
- [`internal`](./internal/EGM.md): Core `goldmark`-based Markdown link
  extraction and filesystem resolution logic (`internal/linkchecker`).

## Invariants

- Relative links across Markdown files checked by [`cmd`](./cmd/EGM.md) and
  [`internal`](./internal/EGM.md) must resolve to existing files on disk
  (either relative to the file's directory or relative to `repoRoot` when
  prefixed with `/`).

## Side Effects

- Running the tooling in [`cmd`](./cmd/EGM.md) traverses the repository tree,
  reads Markdown files, stats resolved target paths, and exits with status
  code `1` if broken links are detected.
