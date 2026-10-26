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

# build

## Overview

Build-time runner configuration script directory (`configure_runner.sh`) for the
`build-runner` image. It configures GCE package mirrors for Debian or Ubuntu,
installs optional APT packages and Python dependencies from
`/google/pyproject.toml` via `uv`, ensures `/usr/local/bin` binaries are
executable, runs build hook scripts in `/build-hooks.d`, and cleans up APT
caches.

## Interface

- `configure_runner.sh`: Executable Bash build-time configuration script
  invoked during container image construction.
- `EXTRA_PKGS`: Optional environment variable specifying space-separated APT
  packages to install during the build.

## Invariants

- Executes under strict shell error handling (`set -euo pipefail`).
- GCE Ubuntu mirror (`gce.archive.ubuntu.com`) is only configured if `getent
hosts gce.archive.ubuntu.com` succeeds.
- `uv` and Python dependencies from `/google/pyproject.toml` are only
  installed if `/opt/antigravity-sdk` exists.
- Build hooks in `/build-hooks.d/*.sh` are executed sequentially in lexical
  glob order via `/bin/bash` if `/build-hooks.d` exists.

## Side Effects

- Overwrites `/etc/apt/sources.list` when running on Debian or on Ubuntu with
  a resolvable `gce.archive.ubuntu.com` host.
- Updates APT indices (`apt-get update`), installs packages listed in
  `EXTRA_PKGS` (`apt-get install -y --no-install-recommends`), removes
  `/var/lib/apt/lists/*`, and runs `apt-get clean`.
- Installs `uv` via `pip3` (`--break-system-packages`) and system Python
  dependencies from `/google/pyproject.toml` via `uv pip install --system`
  when `/opt/antigravity-sdk` is present.
- Sets executable permissions (`chmod +x`) on all files in `/usr/local/bin/*`
  and `/build-hooks.d/*.sh`.
- Executes all `/build-hooks.d/*.sh` scripts.
