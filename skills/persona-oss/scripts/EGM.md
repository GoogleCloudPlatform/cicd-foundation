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

# Open-Source Persona Scripts (`persona-oss/scripts`)

## Overview

Provides Go-based public release-readiness tooling for the `persona-oss` skill,
centered on the `uv_lock_scrubber` pre-commit utility that rewrites non-public
Python registry and wheel/sdist URLs in `uv.lock` files back to canonical
upstream PyPI URLs.

## Interface

- [`cmd`](./cmd/EGM.md): Subdirectory housing the
  [`uv_lock_scrubber`](./cmd/uv_lock_scrubber/EGM.md) CLI binary entry point.
- [`internal`](./internal/EGM.md): Subdirectory housing internal Go packages for
  [`i18n`](./internal/i18n/EGM.md), [`locales`](./internal/locales/EGM.md), and
  [`uvlock`](./internal/uvlock/EGM.md).

## Subdirectories & Boundaries

- [`cmd`](./cmd/EGM.md): Command-line flag parsing (`flag.Parse()`), target
  `uv.lock` discovery, and localized pre-commit exit reporting.
- [`internal`](./internal/EGM.md): Internal implementation packages for
  PyPI JSON metadata resolution, SHA-256 digest verification, and 6-language UN
  localization.

## Invariants

- All Go packages under `skills/persona-oss/scripts` build under the root
  `github.com/GoogleCloudPlatform/cicd-foundation` Go module without introducing
  external third-party dependencies beyond `go-i18n/v2` and `golang.org/x/text`.
- Lockfiles already referencing `https://pypi.org/simple` and
  `https://files.pythonhosted.org/` short-circuit with zero network requests and
  zero filesystem writes.

## Side Effects

- Invoking [`uv_lock_scrubber`](./cmd/uv_lock_scrubber/EGM.md) performs HTTPS
  GET requests against `https://pypi.org/pypi/<pkg>/<version>/json` when
  non-public URLs are present and overwrites modified `uv.lock` files on disk.
