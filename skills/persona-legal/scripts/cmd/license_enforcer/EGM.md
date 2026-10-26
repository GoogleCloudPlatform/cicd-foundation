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

# `license_enforcer` CLI (`cmd/license_enforcer`)

## Overview

Provides the CLI entry point (`package main`) for the `license_enforcer`
utility, which scans repository files and directories to verify and enforce
copyright headers and SPDX license compliance.

## Interface

- `main()`: CLI entry point that initializes localization, parses flags, and
  executes `run()`.
- CLI Flags:
  - `-holder` (`string`): Copyright holder name; defaults to `git config
user.name` via `licensing.ResolveDefaultHolder()`.
  - `-license` (`string`): SPDX license identifier to enforce; defaults to
    `licensing.DiscoverDefaultLicense()`.
  - `-acceptable-licenses` (`string`): Comma- or space-separated list of
    acceptable SPDX license identifiers (default: `""`).
  - `-exclude` (`string`): Space-separated list of path substrings to
    exclude (default: `"node_modules/ dist/ licenses/ check_licenses.py
LICENSE COPYING NOTICE"`).
  - `-filter` (`string`): Regular expression to filter target file paths;
    defaults to `licensing.DefaultFilter()`.
  - `-format` / `-f` (`string`): License header format, `"full"` or `"spdx"`
    (default: `"spdx"`).
- Positional CLI Arguments (`flag.Args()`): Target file or directory paths to
  scan and enforce.

## Invariants

- The trimmed copyright holder string (`-holder`) must be non-empty; otherwise
  execution fails before scanning files.
- The `-filter` pattern must compile as a valid Go regular expression
  (`regexp.Compile`).
- If no positional path arguments are provided, `run()` returns `nil`
  immediately without scanning or modifying files.
- During directory traversal, directories named `.git` or `node_modules` or
  matching any `-exclude` substring are skipped (`filepath.SkipDir`), and only
  files matching the `-filter` regex and not containing any `-exclude`
  substring are processed.
- Concurrent file enforcement via `licensing.EnforceFile` is bounded by
  `concurrencyLimit = 20` goroutines using a buffered channel semaphore.
- Any detected unacceptable licenses (`unacceptableCount > 0`) or in-place
  file modifications (`modifiedCount > 0`) cause `run()` to return an error
  and `main()` to exit with status code `1` (unacceptable license errors take
  precedence over modification errors).

## Side Effects

- Executes `licensing.ResolveDefaultHolder()`,
  `licensing.DiscoverDefaultLicense()`, and `licensing.DefaultFilter()` at
  package initialization time to populate flag defaults.
- Initializes global i18n state via `i18n.Init("", "en", locales.Content)`.
- Reads filesystem metadata (`os.Stat`) and traverses directories
  (`filepath.WalkDir`) for all positional arguments.
- Modifies target files on disk in-place via `licensing.EnforceFile` (adding
  license headers, updating copyright years to `time.Now().Year()`, or fixing
  headers).
- Writes localized status, file modification, holder mismatch, and summary
  messages to `os.Stdout`, and diagnostic/error messages to `os.Stderr`.
- Terminates the process with `os.Exit(1)` when i18n initialization fails,
  holder is empty, files are modified, unacceptable licenses are found, or an
  execution error occurs.
