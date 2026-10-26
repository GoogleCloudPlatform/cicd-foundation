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

# SWE Scripts Internal Packages (`persona-swe/scripts/internal`)

## Overview

Houses internal Go packages backing the `persona-swe` skill's CLI tooling,
including AST-based Markdown relative link verification.

## Interface

- [`linkchecker`](./linkchecker/EGM.md): Parses Markdown files using
  `goldmark` and verifies that relative link and image targets exist on the
  local filesystem.

## Subdirectories & Boundaries

- [`linkchecker`](./linkchecker/EGM.md): Exposes `CheckFile`,
  `IsRelativeLink`, `CleanLink`, `BrokenLink`, and `FileResult` for Markdown
  link validation.

## Invariants

- Internal packages under `internal/` are scoped to the
  `skills/persona-swe/scripts` Go module boundary.
- [`linkchecker`](./linkchecker/EGM.md) ignores external schemes (`http://`,
  `https://`, `mailto:`, `tel:`, `#`, `chrome-extension://`, `file://`) and
  resolves `/`-prefixed links against `repoRoot` and all other relative links
  against the Markdown file's parent directory.

## Side Effects

- [`linkchecker`](./linkchecker/EGM.md) reads Markdown files (`os.ReadFile`)
  and queries target file existence (`os.Stat`) on the local filesystem.
