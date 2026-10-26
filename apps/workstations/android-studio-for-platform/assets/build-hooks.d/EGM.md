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

# ASfP Build Hooks (`build-hooks.d`)

## Overview

Build-time hook scripts for the Android Studio for Platform (`ASFP` / `ASfP`)
workstation image layer that normalize file permissions for dconf profiles and
conditionally manage the ABFS (Android Build File System) APT repository
configuration prior to package installation.

## Interface

- `05_normalize_permissions.sh`: Executable build hook script normalizing
  `/etc/dconf/profile` permissions.
- `30_install_abfs.sh`: Executable and sourceable build hook script defining
  `configure_abfs()` and `main()`.
- `INSTALL_ABFS_CLIENT`: Environment variable input (defaults to `'false'` in
  `30_install_abfs.sh`).

## Invariants

- Both scripts execute under strict Bash mode (`set -euo pipefail`).
- If `/etc/dconf/profile` exists after `05_normalize_permissions.sh` runs, the
  directory has mode `755` and all regular files within it have mode `644`.
- `30_install_abfs.sh` requires `/google/scripts/common.sh` to be present and
  sourceable.
- `/etc/apt/sources.list.d/abfs.list` is retained if and only if
  `INSTALL_ABFS_CLIENT` is set to `'true'`; otherwise it is removed.
- `30_install_abfs.sh` guards execution of `main()` with `[[
"${BASH_SOURCE[0]}" == "${0}" ]]` so it can be sourced without side effects.

## Side Effects

- `05_normalize_permissions.sh` modifies filesystem permissions (`chmod 755`
  on `/etc/dconf/profile` and `chmod 644` on files under `/etc/dconf/profile`)
  and writes status output to stdout.
- `30_install_abfs.sh` sources `/google/scripts/common.sh` and deletes
  `/etc/apt/sources.list.d/abfs.list` via `rm -f` when `INSTALL_ABFS_CLIENT`
  is not `'true'`.
