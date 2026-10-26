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

# Security Persona Scripts (`persona-security/scripts`)

## Overview

Provides security automation scripts for maintaining and refreshing third-party
APT repository GPG keyrings used by Cloud Workstation container images.

## Interface

- `update_gpg_keys.sh`: Bash script that downloads, normalizes, and refreshes
  GPG public keys for third-party APT repositories (`adoptium`,
  `cloud.google`, `docker`, `google-chrome`, `helm`, `nodesource`,
  `nvidia-container-toolkit`, `yarn`).
- `download_key(key_name, url)`: Shell function in `update_gpg_keys.sh` that
  fetches a key from `url` via `curl`, imports it into a temporary GPG
  keyring, and exports an ASCII-armored public key to
  `apps/workstations/gnome/assets/etc/apt/keyrings/<key_name>.asc`.
- `KEYS_TO_DOWNLOAD`: Associative array mapping repository identifiers to
  their upstream GPG key URLs (`ADOPTIUM_KEY_URL`, `GOOGLE_CLOUD_SDK_KEY_URL`,
  `DOCKER_KEY_URL`, `GOOGLE_CHROME_KEY_URL`, `HELM_KEY_URL`,
  `NODESOURCE_KEY_URL`, `NVIDIA_KEY_URL`, `YARN_KEY_URL`).
- `TARGET_DIR`: Output directory path set to
  `apps/workstations/gnome/assets/etc/apt/keyrings`.

## Invariants

- Executes with strict Bash error handling enabled (`set -euo pipefail`).
- All upstream keys (whether binary or ASCII) are imported into an isolated
  temporary GPG homedir (`--homedir "$tmp_dir" --no-default-keyring`) and
  exported strictly as ASCII-armored public key blocks (`--export --armor`)
  with a `.asc` extension as expected by `/etc/apt/sources.list.d/*.list`
  configurations.
- Key URL variables and `KEYS_TO_DOWNLOAD` entries are maintained in
  alphabetical order between `keep-sorted` directives.

## Side Effects

- Creates the directory `apps/workstations/gnome/assets/etc/apt/keyrings`
  (relative to the current working directory) via `mkdir -p`.
- Makes outbound HTTPS requests using `curl -fsSL` to `packages.adoptium.net`,
  `download.docker.com`, `dl.google.com`, `packages.cloud.google.com`,
  `keyserver.ubuntu.com`, `deb.nodesource.com`, `nvidia.github.io`, and
  `dl.yarnpkg.com`.
- Creates and removes temporary directories via `mktemp -d` and `rm -rf`, and
  invokes `gpg` subprocesses to import and export keys.
- Writes and overwrites eight `.asc` GPG keyring files in
  `apps/workstations/gnome/assets/etc/apt/keyrings/` and prints status
  messages to stdout.
