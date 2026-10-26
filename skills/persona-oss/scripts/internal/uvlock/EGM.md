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

# `uv.lock` Registry URL Scrubber (`internal/uvlock`)

## Overview

Implements allowlist-based inspection and rewriting of non-public Python package
registry URLs in `uv.lock` files back to canonical upstream PyPI URLs while
enforcing SHA-256 artifact digest parity.

## Interface

- Constants:
  - `CanonicalPyPIRegistry = "https://pypi.org/simple"`
  - `CanonicalPyPICDNPrefix = "https://files.pythonhosted.org/"`
  - `DefaultPyPIAPIBase = "https://pypi.org/pypi"`
- `type ArtifactInfo struct { URL string; SHA256 string }`: Canonical upstream
  artifact URL and hexadecimal SHA-256 digest for a distribution filename.
- `type MetadataResolver interface { ResolveRelease(ctx context.Context, pkg,
version string) (map[string]ArtifactInfo, error) }`: Abstraction for resolving
  distribution filenames for `<pkg>@<version>` to upstream metadata.
- `type HTTPPyPIResolver struct { APIBase string; Client *http.Client }`:
  Thread-safe, in-memory cached PyPI Warehouse JSON API resolver constructed via
  `NewHTTPPyPIResolver(apiBase string, client *http.Client) *HTTPPyPIResolver`.
- `type ScrubResult struct { Path string; Replacements int; Modified bool }`:
  Outcome summary for a single `uv.lock` file.
- `type Scrubber struct { Resolver MetadataResolver; CheckOnly bool;
MaxConcurrency int }`:
  - `ProcessBytes(ctx context.Context, content []byte) ([]byte, int, error)`:
    Scans `uv.lock` content and rewrites non-public registry and distribution
    URLs when `CheckOnly` is `false`.
  - `ProcessFile(ctx context.Context, filePath string) (ScrubResult, error)`:
    Reads `filePath`, delegates to `ProcessBytes`, and overwrites `filePath` in
    place (preserving file mode permissions) when modifications occur and
    `CheckOnly` is `false`.

## Invariants

- Detection is strictly allowlist-based: any `[[package]]` with a
  `source = { registry = "..." }` entry must equal `CanonicalPyPIRegistry` and
  all `url = "..."` distribution entries within that registry package block must
  start with `CanonicalPyPICDNPrefix`; virtual, editable, Git, and path
  packages (`isRegistryPkg == false`) are left untouched, and any TOML section
  header (`^\[`) resets package scoping.
- When zero non-canonical URLs are found (`neededReplacements == 0`) or
  `CheckOnly` is `true`, `ProcessBytes` returns immediately without requiring a
  non-nil `Resolver` or performing network calls.
- Concurrent `ResolveRelease` calls during `prefetchReleases` are bounded by
  `MaxConcurrency` (defaulting to `12`) and cancel remaining in-flight requests
  on the first resolution error.
- `HTTPPyPIResolver` caches successful `<pkg>@<version>` responses under a mutex
  so duplicate packages across multiple `uv.lock` files trigger at most one HTTP
  request.
- Rewriting fails closed without modifying the target file if:
  1. The distribution filename does not exist in upstream PyPI release metadata;
  2. The upstream metadata URL does not begin with `CanonicalPyPICDNPrefix`; or
  3. The upstream SHA-256 digest does not match the `hash = "sha256:..."` field
     recorded in `uv.lock` (case-insensitive hex comparison).
- Original line endings (`\n` vs `\r\n`) and surrounding TOML formatting are
  preserved byte-for-byte outside replaced URL literals.

## Side Effects

- `HTTPPyPIResolver.ResolveRelease` issues outbound HTTP/HTTPS `GET` requests
  (30s default timeout) to `<APIBase>/<pkg>/<version>/json` and mutates its
  internal mutex-guarded release cache.
- `Scrubber.ProcessFile` reads file metadata and bytes via `os.Stat` /
  `os.ReadFile` and overwrites modified lockfiles via `os.WriteFile` using the
  file's existing permission bits.
