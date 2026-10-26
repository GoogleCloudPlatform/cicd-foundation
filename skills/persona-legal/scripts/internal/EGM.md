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

# Legal Enforcer Internal Packages (`persona-legal/scripts/internal`)

## Overview

Houses internal Go packages backing the `license_enforcer` CLI utility,
including SPDX license detection and header formatting, internationalization
(i18n) bundle management, and embedded locale catalogs.

## Interface

- [`i18n`](./i18n/EGM.md): Initializes the `go-i18n` message bundle and
  provides `T` and `TF` translation helpers.
- [`licensing`](./licensing/EGM.md): Implements SPDX license detection, Git
  holder discovery, comment block formatting, and in-place file header
  enforcement.
- [`locales`](./locales/EGM.md): Embeds localized JSON message catalogs
  (`//go:embed *.json`) for the 6 official United Nations languages (`ar`,
  `en`, `es`, `fr`, `ru`, `zh`).

## Subdirectories & Boundaries

- [`i18n`](./i18n/EGM.md): Localization initialization (`Init`) and message
  lookup (`T`, `TF`).
- [`licensing`](./licensing/EGM.md): Core license header parsing, SPDX clause
  fingerprinting, and file enforcement (`EnforceFile`, `ProcessFileContent`).
- [`locales`](./locales/EGM.md): Compile-time embedded `embed.FS` (`Content`)
  containing localized message templates.

## Invariants

- All internal packages are scoped to the `skills/persona-legal/scripts` Go
  module boundary and cannot be imported outside `persona-legal/scripts`.
- Embedded locale JSON files in [`locales`](./locales/EGM.md) maintain
  alphabetical key ordering by `"id"`, and [`licensing`](./licensing/EGM.md)
  preserves YAML frontmatter, file prologues, and foreign copyright notices.

## Side Effects

- [`i18n`](./i18n/EGM.md) mutates package-level localizer state and reads
  `LANG` from the process environment.
- [`licensing`](./licensing/EGM.md) executes read-only `git` commands (`git
config user.name`, `git rev-parse --show-toplevel`) and reads/overwrites
  target source files during enforcement.
