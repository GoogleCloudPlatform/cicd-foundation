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

# Preflight Web Scripts (`scripts`)

## Overview

Groups build-time scripts for generating static HTML fragments for the
`preflight-web` frontend application.

## Subdirectories & Boundaries

- **Build Scripts**: [`./build/EGM.md`](./build/EGM.md) - Converts
  `privacy_notice.md` into a Tailwind-styled HTML fragment at
  `public/privacy_notice.html` via `generate_fragments.js`.

## Interface

- [`./build/EGM.md`](./build/EGM.md): `generate_fragments.js` CLI build
  script.

## Invariants

- Source markdown (`../../../preflight/docs/privacy_notice.md`) and output
  directory (`public/`) must exist prior to fragment generation.

## Side Effects

- Reads markdown documentation and writes compiled HTML fragments to
  `public/privacy_notice.html`.
