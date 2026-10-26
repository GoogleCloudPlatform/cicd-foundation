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

# Open-Source Expert Persona (`persona-oss`)

## Overview

Defines the Open-Source Expert (`persona-oss`) agent skill and bundles automated
release-scrubbing tooling (`uv_lock_scrubber`) to ensure tracked lockfiles and
source artifacts remain free of private mirror URLs and internal infrastructure
references.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative skill definition, upstream
  contribution playbook, and public release scrubbing workflow for the
  Open-Source Expert persona.
- [`scripts`](./scripts/EGM.md): Go-based automation packages housing the
  [`uv_lock_scrubber`](./scripts/cmd/uv_lock_scrubber/EGM.md) pre-commit CLI.

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): Houses the `uv_lock_scrubber` CLI entry point,
  `uv.lock` registry scrubber engine, and 6-language UN localization catalogs.

## Invariants

- Tracked `uv.lock` files across the repository must reference only canonical
  public PyPI endpoints (`https://pypi.org/simple` and
  `https://files.pythonhosted.org/`) with verified SHA-256 artifact digests as
  enforced by [`scripts`](./scripts/EGM.md).
- No internal mirror hostnames or private domain patterns may be hardcoded in
  scrubbing logic; validation operates strictly via a public upstream allowlist.

## Side Effects

- Executing [`uv_lock_scrubber`](./scripts/cmd/uv_lock_scrubber/EGM.md) queries
  the public PyPI JSON API when non-canonical URLs are detected and rewrites
  affected `uv.lock` files in place (unless `-check` is specified).
