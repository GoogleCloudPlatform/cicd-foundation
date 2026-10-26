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

# Code-OSS DevContainer with gVisor and Terraform (`codeoss-devcontainer-gvisor-terraform`)

## Overview

Provides a standalone DevContainer image definition built on `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest` that installs and registers the gVisor (`runsc`) OCI runtime with the host Docker daemon, adds the Terraform DevContainer feature, and includes a custom local DevContainer feature (`devcontainer-cli-installer`) that installs `@devcontainers/cli` globally via `npm`.

## Interface

- `skaffold.yaml`: Skaffold `v3` configuration building the `codeoss-devcontainer-gvisor-terraform` image via `build_devcontainer $IMAGE`.
- `.devcontainer/devcontainer.json`: Configures the DevContainer build context (`.devcontainer/Dockerfile`), enables `ghcr.io/devcontainers/features/terraform:1` and `./features/devcontainer-cli-installer`, and sets `containerEnv.CLOUD_WORKSTATIONS_ENABLE_METADATA_CREDS_CHECK="false"`.
- `.devcontainer/Dockerfile`: Build arguments `GVISOR_VERSION=20260803.0`, `GVISOR_X86_64_SHA512`, and `GVISOR_AARCH64_SHA512`; sets `ENV CLOUD_WORKSTATIONS_ENABLE_METADATA_CREDS_CHECK=true` during build.
- `.devcontainer/features/devcontainer-cli-installer/install.sh`: Feature installation script parameterized by `VERSION` (default `"latest"`).

## Invariants

- `.devcontainer/Dockerfile` verifies the architecture-specific (`x86_64` or `aarch64`) SHA-512 checksum (`sha512sum -c -`) of `gvisor.tar.bz2` before extracting `/usr/local/bin/runsc` and exits with code `1` on unsupported architectures.
- `.devcontainer/features/devcontainer-cli-installer/install.sh` requires `npm` to be available in `PATH` (after sourcing `/etc/bash.bashrc` if present) or exits with code `1`.

## Side Effects

- Downloads and installs `/usr/local/bin/runsc` and registers it with Docker via `/usr/local/bin/runsc install`.
- Installs `@devcontainers/cli@${VERSION}` globally via `npm install -g`.
