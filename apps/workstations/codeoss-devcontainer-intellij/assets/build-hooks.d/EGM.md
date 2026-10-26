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

# Code-OSS Devcontainer IntelliJ Build Hooks (`build-hooks.d`)

## Overview

Build-time hook scripts for the `codeoss-devcontainer-intellij` workstation
image layer that relocate the host SSH daemon to port `2222`, transform and seed
the IntelliJ devcontainer template into `/etc/skel`, and preload the IntelliJ
Ultimate base container image tarball into `/opt/images`.

## Interface

- `02_configure_sshd_port.sh`: `configure_sshd_port()` and `main()`.
- `08_configure_devcontainer_template.sh`: `configure_template()` and
  `main()`.
- `10_preload_devcontainer_image.sh`: `preload_devcontainer()` and `main()`.
- `INTELLIJ_DEVCONTAINER_BASE_IMAGE`: Optional environment variable (defaults
  to
  `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`).

## Invariants

- All scripts enforce strict bash execution mode via `set -euo pipefail`.
- All scripts guard top-level execution with `if [[ "${BASH_SOURCE[0]}" ==
"${0}" ]]; then main "$@"; fi` so functions can be sourced by unit tests
  without side effects.
- Hook filenames are numerically prefixed (`02_`, `08_`, `10_`) to guarantee
  deterministic alphabetical execution order by `run_hooks`.
- `02_configure_sshd_port.sh` is idempotent and only appends `Port 2222` if
  `/etc/ssh/sshd_config` exists and does not already contain a `^Port 2222`
  directive.
- `08_configure_devcontainer_template.sh` requires `jq` when
  `/opt/devcontainer/intellij/devcontainer.json` is present, removing the
  `.build` object and setting `.image` to `"devcontainer-intellij:latest"`.
- `10_preload_devcontainer_image.sh` requires
  `/google/scripts/build/install_functions.sh` to provide `fetch_crane` and
  `fetch_image`.

## Side Effects

- `02_configure_sshd_port.sh` appends a comment and `Port 2222` to
  `/etc/ssh/sshd_config`.
- `08_configure_devcontainer_template.sh` rewrites
  `/opt/devcontainer/intellij/devcontainer.json` via a temporary `.tmp` file
  and recursively copies `/opt/devcontainer/intellij/*` to
  `/etc/skel/.devcontainer/`.
- `10_preload_devcontainer_image.sh` creates `/opt/images`, downloads and
  installs `/usr/local/bin/crane` via `fetch_crane`, and pulls the IntelliJ
  base container image over the network to `/opt/images/intellij-ultimate.tar`
  via `fetch_image`.
