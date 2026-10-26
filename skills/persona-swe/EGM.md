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

# Software Engineer Persona (`persona-swe`)

## Overview

Defines the Software Engineer (`persona-swe`) agent skill, language-specific
style guide mandates, and automated tooling for verifying structural and
documentation integrity across the repository.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative Software Engineer (SWE) persona
  instructions, i18n and sorting mandates, and style guide references.
- [`scripts`](./scripts/EGM.md): Go module housing the
  [`link_checker`](./scripts/cmd/link_checker/EGM.md) CLI and
  [`linkchecker`](./scripts/internal/linkchecker/EGM.md) package for
  validating relative links in Markdown documentation.

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): Contains the Go module and CLI tooling for
  Markdown relative link verification.

## Invariants

- All code and documentation modifications governed by
  [`SKILL.md`](./SKILL.md) must adhere to language-specific style guides
  (`docs/style_guides/`), 6-language UN internationalization (i18n) standards,
  `go/keep-sorted` directives, and valid relative Markdown links enforced by
  [`scripts`](./scripts/EGM.md).

## Side Effects

- Executing the link checker in [`scripts`](./scripts/EGM.md) reads Markdown
  files across the workspace, verifies target paths via `os.Stat`, and reports
  broken relative links to stdout/stderr.
