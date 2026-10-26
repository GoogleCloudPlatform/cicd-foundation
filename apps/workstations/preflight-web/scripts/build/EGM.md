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

# Preflight Web Build Scripts (`build`)

## Overview

Contains `generate_fragments.js`, a Node.js ES module build script that converts
`../../../preflight/docs/privacy_notice.md` into a Tailwind-styled HTML fragment
at `public/privacy_notice.html` using `marked`.

## Interface

- `generate_fragments.js`: Standalone CLI build script (`node
scripts/build/generate_fragments.js`) with no module exports; defines and
  immediately invokes internal `async function run()`.

## Invariants

- Source file `../../../preflight/docs/privacy_notice.md` (relative to
  `scripts/build`) and target directory `public/` (relative to
  `process.cwd()`) must exist, or the script exits with code `1`.
- Top-level H1 headings (`# ...` or `token.depth === 1`) and HTML comments
  (`<!-- ... -->`) are stripped from the output HTML fragment because the
  modal header renders the main title externally.

## Side Effects

- Immediately executes `run()` upon script load.
- Mutates global `marked` configuration via `marked.setOptions({ breaks: true,
gfm: true })` and `marked.use({ renderer })`.
- Reads `../../../preflight/docs/privacy_notice.md` synchronously from the
  filesystem.
- Writes generated HTML synchronously to `public/privacy_notice.html`
  (relative to `process.cwd()`).
- Writes progress/errors to `stdout`/`stderr` (`console.log`, `console.error`)
  and terminates the process via `process.exit(1)` on failure.
