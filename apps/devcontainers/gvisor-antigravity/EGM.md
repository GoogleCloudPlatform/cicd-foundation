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

# gvisor-antigravity

## Overview

Defines a gVisor-isolated Development Container
(`devcontainer-gvisor-antigravity`) based on Python 3.12
(`mcr.microsoft.com/devcontainers/python:3.12-bookworm`) that packages the
Antigravity CLI (`agy`) and Python SDK for sandboxed execution using the `runsc`
container runtime on Cloud Workstations (CWS).

## Interface

- `skaffold.yaml`: Skaffold configuration (`devcontainer-gvisor-antigravity`,
  `apiVersion: skaffold/v4beta11`) building Docker artifact
  `devcontainer-gvisor-antigravity` from `.devcontainer/Dockerfile`.
- `.devcontainer/Dockerfile`: Container build definition accepting
  `ANTIGRAVITY_CLI_VERSION` (default `1.0.7`), `ANTIGRAVITY_CLI_SHA256`,
  `ANTIGRAVITY_SDK_VERSION` (default `0.1.3`), and `ANTIGRAVITY_SDK_SHA256`,
  and installing `/usr/local/bin/antigravity-cli` (symlinked at
  `/usr/local/bin/agy`) and `/opt/antigravity-sdk` (appended to `PYTHONPATH`).
- `.devcontainer/devcontainer.json`: DevContainer specification (`gVisor
Antigravity DevContainer`) configured with `runArgs: ["--runtime=runsc"]`
  and VS Code extension `ms-python.python`.
- `AGY_ADC_AUTH`: Documented runtime environment variable
  (`AGY_ADC_AUTH=true`) enabling Application Default Credentials (ADC)
  authentication alongside a host bind mount to
  `/home/vscode/.config/antigravity`.

## Invariants

- Base container image is
  `mcr.microsoft.com/devcontainers/python:3.12-bookworm`.
- Downloaded Antigravity CLI (`cli.tar.gz`) and Python SDK (`sdk.tar.gz`)
  release archives must match their configured SHA-256 checksums via
  `sha256sum -c -` during image build.
- Container execution requires the `runsc` (gVisor) Docker runtime
  (`--runtime=runsc`) to be registered on the host environment.

## Side Effects

- Image build updates APT package indices, installs `curl`, and cleans
  `/var/lib/apt/lists/*`.
- Image build fetches release archives over HTTPS from
  `github.com/google-antigravity/antigravity-cli` and
  `github.com/google-antigravity/antigravity-sdk-python`, extracts them to
  `/usr/local/bin` and `/opt/antigravity-sdk`, and updates `PYTHONPATH`.
