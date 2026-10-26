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

# build-hooks.d

## Overview

Contains modular build hook scripts (`01_install_devcontainers_cli.sh`) executed
by `/google/scripts/build/configure_runner.sh` during the `build-runner` image
build. Specifically, it globally installs the `@devcontainers/cli` npm package
at the version specified by `DEVCONTAINER_CLI_VERSION`.

## Interface

- `01_install_devcontainers_cli.sh`: Build hook script invoked via `/bin/bash`
  during image construction.
- `main`: Entry point shell function inside `01_install_devcontainers_cli.sh`.
- `DEVCONTAINER_CLI_VERSION`: Required environment variable specifying the
  target `@devcontainers/cli` version to install.

## Invariants

- Executes with strict Bash error handling (`set -euo pipefail`), failing
  immediately if `DEVCONTAINER_CLI_VERSION` is unset or if `npm install`
  fails.
- Requires `npm` to be installed and available on `PATH`.

## Side Effects

- Writes installation status logs to stdout.
- Executes `npm install -g @devcontainers/cli@${DEVCONTAINER_CLI_VERSION}`,
  fetching packages over the network and installing the `@devcontainers/cli`
  binary and dependencies into the global npm prefix on the container
  filesystem.
