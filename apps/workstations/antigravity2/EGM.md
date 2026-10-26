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

# Antigravity 2.0 Cloud Workstation Layer (`antigravity2`)

## Overview

Cloud Workstation container image layer built on top of `gnome` that installs
the Antigravity 2.0 application into `/opt/Antigravity-x64`, configures
`WORKSTATION_DEFAULT_APP="antigravity"` and `APP_STARTUP_DELAY=5`, and provides
a headless GPU-bypass wrapper (`/usr/local/bin/antigravity`).

## Subdirectories & Boundaries

- **Filesystem Overlay Assets**: [`./assets/EGM.md`](./assets/EGM.md) -
  Contains `01_install_antigravity2.sh` (`build-hooks.d`), the
  `/usr/local/bin/antigravity` wrapper, and `antigravity.desktop`.

## Interface

- [`./assets/EGM.md`](./assets/EGM.md): `01_install_antigravity2.sh`
  (`ANTIGRAVITY2_VERSION`, `ANTIGRAVITY2_SHA256`, `CURL_OPTS`),
  `/usr/local/bin/antigravity` wrapper, and
  `/usr/share/applications/antigravity.desktop`.

## Invariants

- Requires SHA-256 validation of the Antigravity 2.0 tarball before extracting
  into `/opt` and registers `antigravity` as `WORKSTATION_DEFAULT_APP` via
  `/google/scripts/build/configure_workstation.sh`.

## Side Effects

- Downloads and unpacks Antigravity 2.0 into `/opt/Antigravity-x64` and
  registers `antigravity.desktop` for GNOME dock pinning and session
  autostart.
