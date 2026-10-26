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

# Common Workstation Tools (`tools`)

## Overview

Houses compiled utilities built and packaged into the `common` base Cloud
Workstation image.

## Subdirectories & Boundaries

- **Setup Workstation**:
  [`./setup-workstation/EGM.md`](./setup-workstation/EGM.md) - Go CLI utility
  that collects user configuration inputs via TUI forms and applies dotfile
  templates via `chezmoi`.

## Interface

- [`./setup-workstation/EGM.md`](./setup-workstation/EGM.md):
  `setup-workstation` CLI binary and `internal/setup` package.

## Invariants

- Tools are compiled during container image build and installed into
  `/google/bin` (`/export/google/bin/setup-workstation`) for runtime
  invocation across workstation layers.

## Side Effects

- Executes interactive user setup and hydrates configuration templates into
  the workstation user's home directory.
