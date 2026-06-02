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

# Design Document: License Enforcer

## 1. Introduction

The `license_enforcer` is a specialized tool within the `persona-legal` skill set designed to maintain the legal integrity of the repository. It automates the application and maintenance of license headers, which is critical for open-source compliance and intellectual property protection.

## 2. Architecture

The tool is structured into several internal packages to maintain a clean separation of concerns:

- **`cmd/license_enforcer`**: The entry point, handles CLI arguments and orchestrates the file processing pipeline.
- **`internal/licensing`**: The core engine that parses file content, detects existing headers, and applies transformations.
- **`internal/i18n`**: A translation wrapper around `nicksnyder/go-i18n` to support global reach.
- **`internal/locales`**: Embedded JSON files containing translated strings.

## 3. Core Logic: The Stratigraphy of Headers

License enforcement follows a "Geological" approach:

1. **Discovery**: The tool walks the directory tree, respecting excludes and filters.
2. Detection:
   - It identifies the starting copyright year to preserve history.
   - It checks for foreign copyright holders to prevent accidental modification of third-party code (the "Warn and Ignore" policy).
   - **Binary Safety**: It performs a naive check for null bytes (`\0`) to skip binary assets (e.g., images, compiled binaries).
3. Transformation:
   - Redundant or malformed headers are stripped using regular expressions.
   - A fresh header is generated using the original start year and the current year.
   - The header is formatted according to the file extension (e.g., `/** */` for JS/TS/Go, `#` for Python/Shell/YAML/Dockerfile).
   - **Selective Normalization**: Whitespace trimming and trailing newline enforcement are only applied to recognized source file extensions to prevent corruption of unknown formats.
4. Validation: The tool ensures proper spacing and shebang preservation (for scripts).

## 4. Concurrency Model

To handle large repositories efficiently, the tool utilizes a worker pool with a semaphore (`chan struct{}`) to limit concurrent file operations. This prevents hitting OS file descriptor limits while maximizing CPU utilization.

## 5. Security & Safety

- **Read-Only by Default**: The tool only modifies files if there is a substantive change required.
- **Foreign Holder Protection**: Files owned by entities other than the primary holder are never modified automatically.
- **Deterministic Formatting**: Uses standard Go patterns to ensure consistent output across different environments.
