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

# Common Workstation Build Hooks (`build-hooks.d`)

## Overview

Build-time hook scripts in `/build-hooks.d` for the `common` workstation layer
that conditionally download, verify, and install developer and container
tooling: Antigravity CLI (`agy` / `antigravity-cli`) and Python SDK, Agent
Development Kit (`ADK`) for Python, gVisor (`runsc`), and the Devcontainers CLI
(`@devcontainers/cli`).

## Interface

- `04_install_antigravity.sh`: Functions `install_antigravity()` and `main()`;
  environment variables `INSTALL_ANTIGRAVITY_CLI` (default: `true`),
  `ANTIGRAVITY_CLI_VERSION` (default: `1.3.0`), `INSTALL_ANTIGRAVITY_SDK`
  (default: `true`), and `ANTIGRAVITY_SDK_VERSION` (default: `0.1.20`).
- `05_install_adk.sh`: Functions `install_adk()` and `main()`; environment
  variables `INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON` (default: `true`) and
  `ADK_VERSION` (default: `2.3.0`).
- `06_install_gvisor.sh`: Environment variable `INSTALL_GVISOR` (default:
  `false`); constants `GVISOR_VERSION` (`20260803.0`), `GVISOR_X86_64_SHA512`,
  and `GVISOR_AARCH64_SHA512`.
- `07_install_devcontainers.sh`: Environment variable `INSTALL_DEVCONTAINERS`
  (default: `false`).

## Invariants

- All scripts enforce strict shell execution mode (`set -euo pipefail`).
- `04_install_antigravity.sh` and `05_install_adk.sh` are opt-out (enabled by
  default unless their `INSTALL_*` flag is not `true`) and guard `main "$@"`
  with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so they can be sourced without
  executing.
- `06_install_gvisor.sh` and `07_install_devcontainers.sh` are opt-in
  (disabled by default unless `INSTALL_GVISOR=true` or
  `INSTALL_DEVCONTAINERS=true`) and execute at top-level when invoked.
- `06_install_gvisor.sh` only supports `x86_64` and `aarch64` architectures
  (exiting with status `1` otherwise) and requires SHA-512 checksum validation
  (`sha512sum -c -`) of `gvisor.tar.bz2` before extraction.
- `07_install_devcontainers.sh` requires `npm` in `PATH` to install
  `@devcontainers/cli@latest`, logging an error without exiting non-zero if
  `npm` is absent.

## Side Effects

- `04_install_antigravity.sh`: Downloads Antigravity CLI release tarball via
  `curl`, installs `/usr/local/bin/antigravity-cli` (`chmod +x`) and symlink
  `/usr/local/bin/agy`, and downloads/extracts Antigravity Python SDK into
  `/opt/antigravity-sdk`.
- `05_install_adk.sh`: Downloads `google/adk-python` release archive via
  `curl` and extracts it into `/opt/google-adk`.
- `06_install_gvisor.sh`: Downloads `gvisor.tar.bz2` from Google Cloud Storage
  via `wget`, extracts binaries to `/usr/local/bin`, and executes
  `/usr/local/bin/runsc install` to configure the Docker daemon runtime.
- `07_install_devcontainers.sh`: Runs `npm install -g
@devcontainers/cli@latest` to install the Devcontainers CLI globally.
