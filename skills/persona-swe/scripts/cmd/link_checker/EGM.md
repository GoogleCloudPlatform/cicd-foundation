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

# `link_checker` CLI (`cmd/link_checker`)

## Overview

Provides the CLI entry point (`package main`) for the Markdown relative link
checker utility, which scans repository `.md` files and reports broken relative
file and image links.

## Interface

- `main()`: CLI entry point in `package main` for checking Markdown relative
  links.
- Positional CLI Arguments (`flag.Args()` via `flag.Parse()`, supporting the
  `--` separator; no named flags defined): Optional list of file paths to
  check; defaults to scanning the detected repository root when no arguments
  are passed.

## Invariants

- Repository root discovery (`findRepoRoot`) traverses parent directories from
  the current working directory until a `.git` entry is found, falling back to
  the current working directory if none exists.
- Only files with a `.md` suffix are checked; non-`.md` positional arguments
  are ignored.
- Directory tree scanning skips directories in `excludeDirs`: `.git`,
  `.terraform`, `.venv`, `node_modules`, `build`, `dist`, and `tmp`.
- Concurrent calls to `linkchecker.CheckFile(path, repoRoot)` are bounded to
  at most 50 active goroutines via a buffered channel semaphore.

## Side Effects

- Reads filesystem metadata and directory trees via `os.Getwd`, `os.Stat`,
  `filepath.WalkDir`, and `linkchecker.CheckFile`.
- Writes progress summaries and broken link reports to `os.Stdout`, and
  warnings/errors to `os.Stderr`.
- Terminates the process with `os.Exit(0)` if 0 files or 0 broken links are
  found, or `os.Exit(1)` if a repository root, working directory, or walk
  error occurs or any broken links are found.
