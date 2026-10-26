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

# Markdown Link Checker Package (`internal/linkchecker`)

## Overview

Implements AST-based Markdown link extraction and filesystem resolution using
`goldmark` to detect broken relative links and image references within
repository documentation.

## Interface

- `type BrokenLink struct { LineNum int; Link string; ResolvedPath string }`:
  Represents a detected broken link with its 1-indexed line number, raw link
  destination, and resolved filesystem path.
- `type FileResult struct { FilePath string; BrokenLinks []BrokenLink }`:
  Stores broken link scan results for a single file.
- `func IsRelativeLink(link string) bool`: Returns `true` if `link` is
  non-empty and does not start with `http://`, `https://`, `mailto:`, `tel:`,
  `#`, `chrome-extension://`, or `file://`.
- `func CleanLink(link string) string`: Strips `#` anchor fragments and `?`
  query parameters from `link` and trims surrounding whitespace.
- `func CheckFile(path string, repoRoot string) ([]BrokenLink, error)`: Parses
  the Markdown file at `path` using `goldmark`, walks `*ast.Link` and
  `*ast.Image` nodes, resolves relative links, and returns all broken links
  whose resolved targets do not exist.

## Invariants

- Links that are empty or prefixed with `http://`, `https://`, `mailto:`,
  `tel:`, `#`, `chrome-extension://`, or `file://` are excluded by
  `IsRelativeLink`.
- `CleanLink` truncates at the first `#` and then at the first `?` before
  trimming whitespace; links that become empty after cleaning are ignored.
- Cleaned relative links starting with `/` are resolved via
  `filepath.Join(repoRoot, link)`; all other relative links are resolved via
  `filepath.Join(filepath.Dir(path), link)`.
- A link is recorded as a `BrokenLink` only when `os.Stat(resolvedPath)`
  returns an error satisfying `os.IsNotExist(err)`.
- `BrokenLink.LineNum` is 1-indexed (defaulting to `1`, or
  `bytes.Count(source[:offset], []byte("\n")) + 1` when `node.Pos()` is within
  `[0, len(source))`), and `BrokenLink.Link` preserves the uncleaned raw link
  string.

## Side Effects

- Reads the target Markdown file from the local filesystem into memory via
  `os.ReadFile(path)`.
- Queries local filesystem metadata via `os.Stat(resolvedPath)` for each
  resolved relative link.
