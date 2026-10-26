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

# build-runner

## Overview

Defines the multi-stage Docker build (`Dockerfile`) and root filesystem overlay
(`assets/`) for the custom Cloud Build / Skaffold runner image (`build-runner`).
The image extends `gcr.io/k8s-skaffold/skaffold` with the Antigravity CLI
(`antigravity-cli` / `agy`), Antigravity Python SDK (`/opt/antigravity-sdk`),
`@devcontainers/cli`, and the `build_devcontainer` helper script.

## Subdirectories & Boundaries

- `assets`: [`./assets/EGM.md`](./assets/EGM.md) - Root filesystem overlay
  containing `/build-hooks.d`, `/google`, and `/usr/local/bin` scripts and
  manifests.

## Interface

- `Dockerfile`: Multi-stage container build (`fetcher` stage on `alpine:3.19`
  and main stage on `gcr.io/k8s-skaffold/skaffold:${SKAFFOLD_VERSION}`).
- Build arguments (`ARG`): `ALPINE_VERSION` (default `3.19`),
  `SKAFFOLD_VERSION` (default `v2.18.1`), `ANTIGRAVITY_CLI_VERSION` (default
  `1.1.5`), `ANTIGRAVITY_CLI_SHA256`, `ANTIGRAVITY_SDK_VERSION` (default
  `0.1.22`), `ANTIGRAVITY_SDK_SHA256`, `CURL_OPTS`, `DEVCONTAINER_CLI_VERSION`
  (default `0.88.0`), and `EXTRA_PKGS` (default `"curl jq nodejs npm python3
python3-pip"`).
- Container environment variables (`ENV`): `EXTRA_PKGS`,
  `DEVCONTAINER_CLI_VERSION`, and `PYTHONPATH` (appending
  `/opt/antigravity-sdk`).
- Installed binaries and paths: `/usr/local/bin/antigravity-cli`,
  `/usr/local/bin/agy`, `/usr/local/bin/build_devcontainer`, and
  `/opt/antigravity-sdk`.
- [`./assets/EGM.md`](./assets/EGM.md): Overlay scripts and manifests merged
  into `/` during build.

## Invariants

- Downloaded Antigravity CLI (`agy_cli.tar.gz`) and Python SDK
  (`agy_sdk.tar.gz`) archives in the `fetcher` stage must pass SHA-256
  checksum verification (`sha256sum -c -`) against `ANTIGRAVITY_CLI_SHA256`
  and `ANTIGRAVITY_SDK_SHA256`.
- `COPY --from=fetcher /downloads/ /` and `COPY assets/ /` must complete
  before `/bin/bash /google/scripts/build/configure_runner.sh` is executed.

## Side Effects

- Downloads Antigravity CLI and Python SDK release tarballs from GitHub during
  the `fetcher` stage.
- Copies fetched artifacts and `assets/` into the root filesystem of the
  Skaffold base image and executes `/google/scripts/build/configure_runner.sh`
  to install APT packages, Python packages, and `@devcontainers/cli`.
