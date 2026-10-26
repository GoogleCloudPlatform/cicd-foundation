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

# Setup Workstation Internal Packages (`internal`)

## Overview

Houses private implementation packages for the `setup-workstation` CLI tool.

## Subdirectories & Boundaries

- **Setup Engine**: [`./setup/EGM.md`](./setup/EGM.md) - Implements YAML
  config loading, `charmbracelet/huh` interactive prompting, Chezmoi source
  staging, and `chezmoi apply` template hydration.

## Interface

- [`./setup/EGM.md`](./setup/EGM.md): `Options`, `Config`, `PermissionRule`,
  `Input`, `Shell`, `OSShell`, `Run`, `IsDone`, and `CheckRunnable`.

## Invariants

- Enforces strict YAML schema validation (`KnownFields(true)`), `0600`
  permissions on `~/.config/chezmoi/chezmoi.yaml`, and completion tracking via
  `$XDG_STATE_HOME/setup-workstation-done`.

## Side Effects

- Reads configuration and environment state, runs interactive TUI prompts,
  invokes `chezmoi`, and writes hydrated dotfiles and completion state markers
  to the user home directory.
