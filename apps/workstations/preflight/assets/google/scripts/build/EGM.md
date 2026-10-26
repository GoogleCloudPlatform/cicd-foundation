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

# Preflight Build Scripts (`build`)

## Overview

Contains `build_web.sh`, a POSIX shell (`#!/bin/sh`) build script executed
during the `web-builder` Docker stage to conditionally fetch, compile, and stage
the Preflight SPA (Single Page Application) frontend into `/build/web/dist`.

## Interface

- `build_web.sh <PREFLIGHT_WEB_REPO> <PREFLIGHT_WEB_DIR>`: Positional
  arguments `$1` (`PREFLIGHT_WEB_REPO`, optional Git repository URL/path) and
  `$2` (`PREFLIGHT_WEB_DIR`, optional relative subdirectory inside the cloned
  repository, defaulting to `.`).
- `perform_build <source_path>`: Internal shell function that changes into
  `<source_path>`, executes `npm install --silent && npm run build`, and
  copies `<source_path>/dist/.` into `/build/web/dist/`.

## Invariants

- Executes under `set -e`, aborting immediately on any command failure.
- `BUILD_DIST_DIR` (`/build/web/dist`) is unconditionally created via `mkdir
-p` before source resolution so downstream Docker stages always have a valid
  `/build/web/dist` directory even when the build is skipped.
- Source selection follows a strict precedence: (1) if `PREFLIGHT_WEB_REPO` is
  non-empty, clones the repository into `repo` and builds
  `repo/${PREFLIGHT_WEB_DIR:-.}`; (2) else if `/build/web/source` exists and
  contains `/build/web/source/package.json`, builds `/build/web/source`; (3)
  otherwise logs a message and skips the SPA build.
- Assumes `npm run build` in `<source_path>` outputs artifacts to
  `<source_path>/dist`.

## Side Effects

- Creates `/build/web/dist` on the local filesystem.
- Clones remote or external Git repository into `./repo` via `git clone` when
  `PREFLIGHT_WEB_REPO` is provided.
- Changes working directory to `<source_path>`, installs npm dependencies
  (`npm install --silent`), runs `npm run build`, and recursively copies
  `dist/.` to `/build/web/dist/` preserving file attributes (`cp -pR`).
- Writes progress and skip messages to stdout.
