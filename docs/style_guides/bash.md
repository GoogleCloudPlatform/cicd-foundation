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

# Bash Style Guide

This project follows the [Google Bash Style Guide](https://google.github.io/styleguide/shellguide.html) while incorporating established [Bats-core](https://github.com/bats-core/bats-core) community conventions for test-related files.

## Key Principles

1. **Strict Mode**: Always start scripts with `set -euo pipefail` to ensure robust error handling.
2. **Function Definitions**: Declare functions without the `function` keyword (e.g., `my_func() { ... }`).
3. **Local Variables**: Always use `local` for variables declared inside functions to prevent global scope pollution.
4. **Conditionals**: Prefer `[[ ... ]]` over `[ ... ]` or `test` for boolean checks.
5. **Multi-line Strings**: Always use Heredocs (`cat <<EOF ... EOF`) instead of heavily escaped multi-line strings for generating configurations or blocks of text. This drastically improves readability and maintainability.
6. **Logging**: Always utilize the standardized `log`, `warn`, and `error` functions from `common.sh`.
   - **Mandate**: Do not use raw `echo` for script telemetry or status reporting.
   - **`error`**: Use for terminal failures. It automatically exits with code 1.
7. **Linting**: All scripts must pass `shellcheck` cleanly. Use `# shellcheck disable=SC...` only when absolutely necessary and document the reason.
8. **Main Function**: Wrap the primary logic of executable scripts in a `main()` function and call it at the end of the script (`main "$@"`). This improves variable scoping and readability.

## Deviations & Project-Specific Conventions

While we aim for maximum compliance with the Google Style Guide, this project implements the following specific conventions and exceptions:

### 1. Filename Conventions (Underscores over Hyphens)

- **Convention**: All script filenames must use underscores (`_`) instead of hyphens (`-`).
- **Rationale**: Ensures internal consistency across the blueprint and maintains a uniform visual style in the `scripts/` and `assets/` directories.
- **Example**: `monitor_build.sh`, not `monitor-build.sh`.

### 2. BATS Helper Extensions (`.bash`)

- **Exception**: Files intended to be `load`-ed by the **Bats-core** framework (test helpers) use the `.bash` extension.
- **Rationale**: Adheres to the established [standard BATS community pattern](https://bats-core.readthedocs.io/en/stable/writing-tests.html#loading-libraries) to distinguish helpers from executable scripts (`.sh`) and test files (`.bats`).
- **Exemption**: **Files with the `.bash` extension are NOT subject to the Google Style Guide.** They do not require a `main()` function or other guide-specific structures, as they are libraries intended for sourcing by Bats.

### 3. Blank Line after Shebang

- **Convention**: A single blank line must be inserted between the `#!` shebang and the license header.
- **Rationale**: Improves readability and clearly separates the interpreter directive from the legal documentation.

### 4. Directory Independence

- **Convention**: Scripts must execute correctly regardless of the caller's current working directory.
- **Requirement**: Use the `BASH_SOURCE` pattern and a robust lookup to determine the project root.
- **Recommended Pattern**: Use the `find_repo_root` utility (documented below) to locate the project root and then source the centralized registry.

### 5. Core Infrastructure Registry (`common.sh`)

- **Authoritative Source**: `skills/common.sh` is the central registry for all repository-wide standards.
- **Mandate**: All executable scripts (`.sh`) and test helpers (`.bash`) MUST source `skills/common.sh`.
- **Functionality Provided**:
  - **Environment Loading**: Automatically loads `.env` files.
  - **Path Management**: Exports a stable `REPO_ROOT` variable.
  - **Standardized Logging**: Provides `log`, `warn`, and `error` functions.
  - **Fallback Logic**: Sets consistent defaults for `REGION`, `PROJECT`, etc.
- **Bootstrap Pattern**:

  ```bash
  # 1. Define the bootstrap lookup
  find_repo_root() {
    local dir="${1}"
    while [[ "${dir}" != "/" ]]; do
      if [[ -f "${dir}/skills/common.sh" ]]; then
        echo "${dir}"
        return 0
      fi
      dir="$(dirname "${dir}")"
    done
    return 1
  }

  # 2. Source the central registry
  PROJECT_ROOT="$(find_repo_root "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
  # shellcheck disable=SC1091
  source "${PROJECT_ROOT}/skills/common.sh"
  ```

### 6. Sourcing Guards

- **Convention**: Executable scripts that might be sourced for their functions MUST use a sourcing guard to prevent accidental execution of the `main` logic.
- **Rationale**: Prevents side effects when a script is sourced for unit testing or as a library.
- **Pattern**:
  ```bash
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
  fi
  ```

### 7. Variable Naming

- **Global Variables**: Use `UPPER_CASE` for constants, exported environment variables, and script-wide globals.
- **Local Variables**: Use `lower_case` (snake_case) for all variables declared with `local` inside functions.
- **Rationale**: Clearly distinguishes the scope and origin of variables, improving readability and preventing accidental overwrites.
- **Example**:

  ```bash
  readonly TIMEOUT=60

  my_func() {
    local current_time
    current_time=$(date +%s)
    ...
  }
  ```

## Testing Bash Scripts

All Bash scripts and CLI workflows must be tested using the **Bats-core** (Bash Automated Testing System) framework.

### How to Write Tests

1. **Unit vs. Integration**:
   - Unit Tests (`tests/`): Test individual bash functions by `source`-ing the script and invoking the function directly in a mocked environment (e.g., using `mktemp -d`).
   - Integration Tests (`tests/integration/`): Test the full end-to-end execution of scripts in the live Cloud Workstation environment via SSH.
2. **Setup and Teardown**: Use Bats' native `setup()` and `teardown()` hooks to prepare and clean up the test environment.
3. **Assertions**: Use the `run` command to capture execution. Always assert against both the `$status` (exit code) and the `$output` string.
   ```bash
   @test "log output contains message" {
     run log "This is a test"
     [ "$status" -eq 0 ]
     [[ "$output" =~ "This is a test" ]]
   }
   ```

## 8. Structured Logging (Observability)

To support Service Level Objectives (SLOs) and system-wide observability, all critical lifecycle events must be logged as structured JSON.

### The `log_event` Function

Utilize `log_event` from `common.sh` for all significant state changes. This function uses a pretty-printed JSON template at `/google/templates/log.json.template` to define the schema, but flattens the output into a single line for ingestion.

- **Usage**: `log_event EVENT_NAME "Human readable message" [SEVERITY] [KEY=VALUE ...]`
- **Naming Convention**: Use `UPPER_SNAKE_CASE` for event names (e.g., `IMAGE_BOOTING`, `SERVICE_READY`).
- **Standard Fields**: The function automatically includes `timestamp`, `severity`, `event`, `message`, `service`, and a nested `metadata` object for any additional key-value pairs.
- **Unification**: Standard logging functions (`log`, `warn`, `error`) are wrappers for `log_event` and emit the same structured format.

### Mandatory Instrumentation Points

Every custom image blueprint must instrument the following points:

1. **`IMAGE_BOOTING`**: Emitted by the very first script in the entrypoint sequence.
2. **`SYSTEMD_STARTING`**: Emitted just before the handover to the systemd init process.
3. **`SERVICE_STARTING` / `SERVICE_READY`**: Emitted at the beginning and end of major orchestration services (e.g., `user-setup`, `config-rendering`).
4. **`IMAGE_READY`**: Emitted when the final gateway is open and the workstation is reachable.

### Example

```bash
log_event SERVICE_READY "GNOME session is active" SERVICE=gnome-session
```
