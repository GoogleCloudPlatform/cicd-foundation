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

# Manifest Generator (`presentations/md2tty/scripts`)

## Overview

Node.js build script (`generate-manifest.js`) that prepares slide and locale
assets for the `md2tty` presentation engine by copying markdown slides to
`public/slides`, generating a sorted slide manifest at `public/slides.json`,
copying locale JSON files to `public/locales`, and transpiling locale JSON
entries into Bash associative array scripts (`locales/<lang>.sh`).

## Interface

- `main()`: Script entry point in `generate-manifest.js`, executed immediately
  on load (no module exports).
- `process.env.SLIDES_SRC`: Optional environment variable overriding the
  default `../slides` source directory.

## Invariants

- All pre-existing files in `../public/slides` are removed before copying
  current slide files.
- Only files ending with `.md` in `SOURCE_DIR` are copied and recorded in
  `../public/slides.json`.
- Slide filenames in `../public/slides.json` are sorted using natural numeric,
  case-insensitive ordering (`localeCompare` with `{ numeric: true,
sensitivity: 'base' }`).
- Locale JSON files in `../locales` must parse as arrays of `{ id, translation
}` objects; single quotes in translations are escaped as `'\''` inside
  generated `declare -g -A i18n_<lang>` Bash associative arrays.

## Side Effects

- Creates `../public`, `../public/slides`, and `../public/locales` directories
  on the filesystem if missing.
- Deletes all existing files inside `../public/slides`.
- Copies `*.md` files from `SOURCE_DIR` to `../public/slides` and `*.json`
  files from `../locales` to `../public/locales`.
- Writes generated Bash locale scripts (`../locales/<lang>.sh`) and the slide
  manifest file (`../public/slides.json`).
- Writes status messages and warnings to `stdout` and `stderr` via
  `console.log` and `console.warn`.
