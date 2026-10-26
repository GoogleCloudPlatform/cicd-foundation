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

# Open-Source Scripts Internal Packages (`persona-oss/scripts/internal`)

## Overview

Houses internal Go packages backing the `uv_lock_scrubber` CLI utility,
including `uv.lock` registry URL scrubbing and PyPI digest verification,
internationalization (i18n) bundle management, and embedded locale catalogs.

## Interface

- [`i18n`](./i18n/EGM.md): Initializes the `go-i18n` message bundle and provides
  `T` and `TF` translation helpers.
- [`locales`](./locales/EGM.md): Embeds localized JSON message catalogs
  (`//go:embed *.json`) for the 6 official United Nations languages (`ar`, `en`,
  `es`, `fr`, `ru`, `zh`).
- [`uvlock`](./uvlock/EGM.md): Implements allowlist-based `uv.lock` inspection,
  concurrent cached PyPI JSON metadata resolution, SHA-256 digest verification,
  and in-place URL rewriting.

## Subdirectories & Boundaries

- [`i18n`](./i18n/EGM.md): Localization initialization (`Init`) and message
  lookup (`T`, `TF`).
- [`locales`](./locales/EGM.md): Compile-time embedded `embed.FS` (`Content`)
  containing localized message templates.
- [`uvlock`](./uvlock/EGM.md): Core lockfile parser/rewriter (`Scrubber`) and
  PyPI Warehouse JSON API client (`HTTPPyPIResolver`).

## Invariants

- All internal packages are scoped to the `skills/persona-oss/scripts/internal`
  tree and cannot be imported outside `skills/persona-oss/scripts`.
- Embedded locale JSON files in [`locales`](./locales/EGM.md) maintain
  alphabetical key ordering by `"id"`, and [`uvlock`](./uvlock/EGM.md) never
  embeds internal domain names or private mirror hostnames.

## Side Effects

- [`i18n`](./i18n/EGM.md) mutates package-level localizer state and reads `LANG`
  from the process environment.
- [`uvlock`](./uvlock/EGM.md) performs HTTPS GET requests to the configured PyPI
  JSON API endpoint and reads/overwrites target `uv.lock` files on disk.
