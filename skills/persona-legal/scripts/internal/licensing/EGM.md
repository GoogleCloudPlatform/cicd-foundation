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

# License Detection and Enforcement (`internal/licensing`)

## Overview

Provides SPDX license detection, copyright holder resolution via Git
configuration, comment header formatting across language families, and in-place
file license header enforcement.

## Interface

- `var HashStyleExtensions []string`, `var HTMLStyleExtensions []string`, `var
CStyleExtensions []string`: File extension classification lists for comment
  formatting.
- `var Licenses map[string]string`: Map of SPDX identifiers (`Apache-2.0`,
  `GPL-2.0-only`, `MIT`) to full license template texts loaded from embedded
  `assets/*.txt`.
- `func FindRepoRoot() string`: Resolves the repository root via `git
rev-parse --show-toplevel` or ancestor lookup for `.git`, `LICENSE`,
  `LICENSE.txt`, or `LICENSE.md`.
- `func NormalizeLicenseText(content string) string`: Normalizes line endings,
  strips copyright lines, and collapses whitespace for deterministic hashing.
- `func ComputeHash(text string) string`: Computes the hexadecimal SHA-256
  digest of normalized license text.
- `func MapLicenseTextToSPDX(content string) string`: Maps raw license text to
  an SPDX identifier (`Apache-2.0`, `MIT`, `BSD-3-Clause`, `BSD-2-Clause`,
  `GPL-3.0-only`, `GPL-2.0-only`, `MPL-2.0`, `CC0-1.0`) via SPDX tags or
  clause fingerprinting.
- `func DiscoverDefaultLicense() string`: Scans the repository root for
  `LICENSE`, `LICENSE.txt`, `LICENSE.md`, or `COPYING` and returns its SPDX
  identifier (defaulting to `"Apache-2.0"`).
- `func GitAuthorName() (string, error)`: Retrieves `user.name` from `git
config`.
- `func ResolveDefaultHolder() (string, error)`: Resolves the default
  copyright holder from `GitAuthorName()`, returning an error if unset or
  empty.
- `func DefaultFilter() string`: Builds the default regular expression
  matching supported file extensions plus `Dockerfile` and `Makefile`.
- `func ParseLicenseList(input string) []string`: Splits a comma- or
  whitespace-delimited string of SPDX identifiers.
- `func IsLicenseAcceptable(detected string, primary string, acceptable
[]string) bool`: Performs case-insensitive comparison against the primary
  and acceptable SPDX license list.
- `func DetectExistingLicense(content string) string`: Inspects leading YAML
  frontmatter (`reFrontmatter` / `reFrontmatterLicense`) and extracts the
  entire leading comment block (`extractLeadingHeader(content)`) to identify
  an existing SPDX tag or license header.
- `type HeaderFormatter struct{}`: Formats raw license text into
  language-appropriate comment blocks (`Format(text, ext string) string`,
  `FormatWithStyle(text, ext, formatStyle string) string`).
- `type Result struct { Modified bool; LicenseAdded bool; YearUpdated bool;
DifferentHolder string; UnacceptableLicense string }`: Reports the outcome
  of processing a single file.
- `func ProcessFileContent(content string, ext string, currentYear int, holder
string, targetLicense string, format string, acceptableLicenses ...string)
(string, Result)`: Pure transformation that validates, updates, or injects
  license headers into file content.
- `func StripRedundantHeaders(content string) string`: Strips C-style (`reC`)
  and HTML-style (`reHTML`) copyright comment blocks from `content` before
  `ProcessFileContent` re-applies the canonical header.
- `func EnforceFile(path string, currentYear int, holder string, targetLicense
string, format string, acceptableLicenses ...string) (Result, error)`: Reads
  `path`, applies `ProcessFileContent`, and writes modified content back to
  disk.

## Invariants

- Package `init()` panics if reading embedded `assets/*.txt` from
  `licenseAssets` fails.
- Files with unsupported extensions (where `HeaderFormatter.FormatWithStyle`
  returns `""`) are returned unmodified by `ProcessFileContent`.
- If an existing license is detected and is not in the acceptable set
  (`targetLicense` or `acceptableLicenses`, matched case-insensitively),
  `ProcessFileContent` returns the original content unmodified with
  `Result.UnacceptableLicense` set.
- If an existing license is acceptable but differs from `targetLicense`, or if
  an existing copyright notice belongs to a different holder,
  `ProcessFileContent` leaves the content unmodified and records
  `Result.DifferentHolder` when applicable.
- Leading YAML frontmatter (delimited by `---`) is preserved prior to license
  processing and restored at the start of the output; if the frontmatter
  defines a `license:` field, no comment license header is injected.
- File prologues (`#!`, `<?xml`, `<?php`, `<!doctype`) are kept on the first
  line above any newly inserted license header.
- `CStyleExtensions` use `/** ... */` block comments in `"full"` mode and `//`
  line comments in `"spdx"` mode, except for the `"css"` extension which
  always uses `/** ... */` block comments.
- Existing copyright years for the target holder that are strictly less than
  `currentYear` are updated to `<startYear>-<currentYear>`.
- `EnforceFile` treats any non-empty file containing a NUL byte (`0x00`) as
  binary and returns an empty `Result` without modifying the file.
- `EnforceFile` resolves `.template` and `.tmpl` suffixes to their underlying
  file extension and maps basenames `Dockerfile` and `Makefile` to
  `"dockerfile"` and `"makefile"`.

## Side Effects

- Package `init()` reads embedded license templates from `assets/*.txt` and
  populates the exported global map `Licenses`.
- `FindRepoRoot()` and `GitAuthorName()` execute `git` subprocesses (`git
rev-parse --show-toplevel` and `git config user.name`).
- `DiscoverDefaultLicense()` reads `LICENSE`, `LICENSE.txt`, `LICENSE.md`, or
  `COPYING` from the repository root.
- `EnforceFile` reads files from the local filesystem via `os.ReadFile` and
  overwrites modified files via `os.WriteFile` with mode `0644`.
