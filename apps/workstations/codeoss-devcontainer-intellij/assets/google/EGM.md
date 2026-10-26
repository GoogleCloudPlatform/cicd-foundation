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

# Code-OSS Devcontainer IntelliJ Google Assets (`google`)

## Overview

Houses runtime scripts under `/google` for the `codeoss-devcontainer-intellij`
workstation layer.

## Subdirectories & Boundaries

- **Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Provides
  `start_intellij_devcontainer.sh` to load cached Docker images and start the
  user's IntelliJ devcontainer.

## Interface

- [`./scripts/EGM.md`](./scripts/EGM.md): `start_intellij_devcontainer.sh`
  (`main`, `WORKSTATION_USER`).

## Invariants

- Requires `/google/scripts/common.sh` and a responsive Docker daemon within
  60 seconds before starting the devcontainer.

## Side Effects

- Loads cached Docker tarballs from `/opt/images`, runs `devcontainer up`, and
  emits `DEVCONTAINER_READY` log events.
