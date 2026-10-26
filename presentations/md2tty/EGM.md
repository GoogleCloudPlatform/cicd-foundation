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

# Markdown to TTY Presentation System (`presentations/md2tty`)

## Overview

Provides a dual-runtime terminal-styled interactive Markdown presentation
system: a terminal presentation runner built on `gum format` (`bin/md2tty.sh`),
a browser-based ES module library (`src/md2tty.js` and submodules), a static
asset and manifest generator (`scripts/generate-manifest.js`), and a Vite build
configuration (`vite.config.js`) that bundles `src/md2tty.js` and its
dependencies into `dist/md2tty.js` and `dist/md2tty.css`.

## Interface

- `vite.config.js`: Default export defining the Vite configuration and ES
  library build entry (`src/md2tty.js` as `Md2tty` -> `dist/md2tty.js` and
  `dist/md2tty.css`).
- `test_extract.sh` & `test_show_shortcuts.sh`: Shell test scripts verifying
  slide extraction and interactive shortcut modal behavior in `bin/md2tty.sh`.
- **Terminal Presentation Runner**: [`./bin/EGM.md`](./bin/EGM.md) -
  Terminal-based Markdown presentation script (`md2tty.sh`) built on `gum
format` with ANSI 256-color and OSC 8 formatting, background luma detection,
  localization, and shortcut navigation.
- **Manifest Generator**: [`./scripts/EGM.md`](./scripts/EGM.md) - Node.js
  build script (`generate-manifest.js`) that copies slide and locale assets,
  builds `public/slides.json`, and transpiles locale JSON files into Bash
  associative arrays.
- **Browser Presentation Engine**: [`./src/EGM.md`](./src/EGM.md) -
  Client-side JavaScript presentation engine (`Md2tty`, `initI18n`,
  `autoScale`, `initSlides`, `renderAllSlides`, `activateSlide`, `toggleHelp`,
  `toggleTheme`, `flashTheme`).

## Invariants

- Vite library build targets ES module format (`formats: ['es']`) from entry
  `src/md2tty.js` with `emptyOutDir: true` into `dist/`, renaming `style.css`
  output asset to `md2tty.css` while bundling `marked` into `dist/md2tty.js`
  rather than marking it external.
- Both `npm run dev` and `npm run build` execute
  `scripts/generate-manifest.js` prior to invoking Vite to ensure slide and
  locale manifests are populated before bundling or serving.
- Both the terminal script (`bin/md2tty.sh`) and client-side engine (`src/`)
  support multi-language localization (`en`, `es`, `fr`, `ru`, `zh`, `ar`),
  theme toggling/detection, slide navigation, and keyboard shortcut overlays.

## Side Effects

- Running the Vite dev server (`vite`) automatically opens the browser
  (`server.open: true`).
- Running `vite build` clears `dist/` (`emptyOutDir: true`) and writes the
  bundled ES module (`dist/md2tty.js`) and CSS (`dist/md2tty.css`) assets.
- `scripts/generate-manifest.js` writes slide and locale asset manifests to
  the filesystem based on `process.env.SLIDES_SRC`.
- `bin/md2tty.sh` interacts with the terminal TTY, executes `gum format`, and
  reads/generates locale files; `src/` mutates browser DOM state, styles, and
  event listeners.
