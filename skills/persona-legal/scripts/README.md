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

# License Enforcer

A command-line utility to automate the enforcement of license headers across a multi-language codebase. It ensures that every source file contains the correct copyright notice and license text, updating years where necessary and warning about third-party copyright holders.

## Features

- **Multi-Language Support**: Supports `.ts`, `.js`, `.cjs`, `.mjs`, `.jsx`, `.tsx`, `.sh`, `.py`, `.html`, `.md`, `.go`, `.yaml`, `.yml`, `.conf`, `.list`, `.xml`, `.template`, `.tmpl`, and `Dockerfile`.
- **Geological Year Tracking**: Automatically updates copyright years (e.g., `2024` -> `2024-2026`).
- **Safety First**:
  - Skips binary files (null-byte detection).
  - Skips files with foreign copyright holders to prevent legal ambiguity.
  - **Header Preservation**: Guaranteed to never leave a file without a header if one already existed.
- **Metadata-Driven Licensing**: Supports the `agentskills.io` specification by recognizing a `license` field in YAML frontmatter as a valid substitute for physical comment headers (currently enabled for `.md` files).
- **Template Resolution**: Intelligently resolves underlying extensions for `.template` and `.tmpl` files.
- **Internationalization**: Full i18n support for user-facing strings.
- **Concurrent Processing**: High-performance execution using a worker pool.

## Usage

```bash
go run skills/persona-legal/scripts/cmd/license_enforcer/main.go [flags] [paths...]
```

### Flags

- `-holder`: The copyright holder name (default: "Google LLC").
- `-license`: The SPDX license identifier (default: "Apache-2.0").
- `-exclude`: Space-separated list of paths to ignore.
- `-filter`: Regex pattern for files to include.

## Development

### Running Tests

```bash
cd skills/persona-legal/scripts
go test ./...
```

### Adding New Licenses

License templates are stored in `internal/licensing/assets/`. Add a `.txt` file named after the SPDX identifier to include a new license.
