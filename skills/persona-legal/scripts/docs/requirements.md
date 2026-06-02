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

# Technical Requirements: License Enforcer

## 1. Functional Requirements (The "What")

- **FR1: Full Header Application**: The tool MUST apply a complete license header to files missing one, including copyright year, holder, and SPDX license text (default: Apache-2.0).
- **FR2: Geological Year Management**: The tool MUST detect original copyright years and automatically update them to a range (e.g., `2024-2026`) if the start year is in the past.
- FR3: Language-Specific Formatting: The tool MUST support C-style (`/** */`), Hash (`#`), and HTML/XML (`<!-- -->`) comment styles based on file extension. Supported extensions include `.ts`, `.js`, `.cjs`, `.mjs`, `.jsx`, `.tsx`, `.go`, `.sh`, `.py`, `.yaml`, `.yml`, `.conf`, `.list`, `.html`, `.md`, `.xml`, `.template`, `.tmpl`, and `Dockerfile`.
- FR4: Shebang Preservation: The tool MUST detect and preserve shebang lines (`#!`) at the top of scripts, ensuring the license header is placed immediately below them.
- FR5: Foreign Holder Safety (Warn and Ignore): The tool MUST detect copyright holders that do not match the target holder and skip those files to prevent legal ambiguity.
- FR6: CLI Interface: The tool MUST provide a CLI with flags for custom holders, license types, excludes, and file filters.
- FR7: Binary File Detection: The tool MUST detect binary files using a null-byte check and skip them to prevent data corruption.
- FR8: Template and Alias Resolution: The tool MUST correctly resolve the underlying file extension for `.template` and `.tmpl` files (e.g., `config.sh.tmpl` -> `sh`) to ensure appropriate header formatting.
- FR9: Header Preservation: The tool MUST NEVER leave a file without a license header if one already existed. It MUST verify that it has a valid formatter for the file's resolved extension before attempting to strip or replace existing headers.

## 2. Non-Functional Requirements (The "How Well")

- **NFR1: High-Performance Concurrency**: The tool MUST process files concurrently using a worker pool to handle thousands of files in under 10 seconds.
- **NFR2: Global Reach (i18n)**: All user-facing strings MUST be localized across the 6 official UN languages (ar, en, es, fr, ru, zh).
- **NFR3: Go Readability & Maintainability**: Code MUST strictly adhere to Google Go Readability standards, pass `golangci-lint`, and include comprehensive package documentation.
- **NFR4: CI Compatibility**: The tool MUST provide a non-zero exit code if any files were modified, enabling its use as a pre-commit hook or CI validation gate.

## 3. Compliance & Legal

- **CL1: Self-Enforcement**: The tool MUST itself include the Apache-2.0 license header in all its source files.
- **CL2: SPDX Alignment**: The tool SHOULD align with SPDX identifiers for license template management.
