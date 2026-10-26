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

# intellij

## Overview

Defines a standalone Development Container and Skaffold build configuration
(`devcontainer-intellij`) for an IntelliJ IDEA Ultimate remote development
environment based on the Cloud Workstations predefined image
(`us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`),
pre-installed with the Antigravity CLI (`antigravity-cli` / `agy`) and
Antigravity Python SDK (`/opt/antigravity-sdk`).

## Interface

- `skaffold.yaml`: Skaffold configuration (`devcontainer-intellij`,
  `apiVersion: skaffold/v3`) building artifact image `devcontainer-intellij`
  via custom build command `build_devcontainer $IMAGE`.
- `.devcontainer/devcontainer.json`: DevContainer specification (`IntelliJ
Ultimate Devcontainer`) building `.devcontainer/Dockerfile` with context
  `..`, mapping `appPort: ["22:22"]`, `forwardPorts: [22]`, `remoteUser:
"user"`, and `overrideCommand: false`.
- `.devcontainer/Dockerfile`: Container build definition accepting
  `DEBIAN_FRONTEND=noninteractive`, `ANTIGRAVITY_CLI_VERSION` (default
  `1.1.22`), `ANTIGRAVITY_CLI_SHA256`, `ANTIGRAVITY_SDK_VERSION` (default
  `0.1.15`), and `ANTIGRAVITY_SDK_SHA256`, and installing
  `/usr/local/bin/antigravity-cli`, symlink `/usr/local/bin/agy`, and
  `/opt/antigravity-sdk` on `PYTHONPATH`.

## Invariants

- UID `1000` is reserved for the `user` account with passwordless `sudo`
  (`/etc/sudoers.d/user` with permissions `0440`); any existing non-`user`
  account with UID `1000` is removed during build.
- Antigravity CLI and Python SDK release tarballs must pass SHA-256
  verification against `ANTIGRAVITY_CLI_SHA256` and `ANTIGRAVITY_SDK_SHA256`
  via `sha256sum -c -` during Docker build.
- Base image startup command is preserved (`overrideCommand: false` in
  `.devcontainer/devcontainer.json`).

## Side Effects

- Docker build installs `curl` and `sudo` via `apt-get`, modifies system user
  accounts and `/etc/sudoers.d/user`, fetches release archives over HTTPS from
  `github.com/google-antigravity/antigravity-cli` and
  `github.com/google-antigravity/antigravity-sdk-python`, and installs files
  into `/usr/local/bin` and `/opt/antigravity-sdk`.
- DevContainer runtime exposes and forwards TCP port `22:22` for SSH remote
  development.
- Skaffold build executes custom build script `build_devcontainer $IMAGE`.
