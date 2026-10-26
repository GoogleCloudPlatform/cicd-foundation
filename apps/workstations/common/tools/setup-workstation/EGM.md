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

# Setup Workstation (`setup-workstation`)

## Overview

Go CLI utility that guides users through interactive first-time Cloud
Workstation personalization using `charmbracelet/huh` TUI forms and hydrates
configuration file templates into the user's home directory via `chezmoi`.

## Subdirectories & Boundaries

- **CLI Entrypoint**: [`./cmd/EGM.md`](./cmd/EGM.md) - Defines the
  `setup-workstation` command-line interface, flag parsing, and
  `--needs-setup` exit-code contract.
- **Internal Implementation**: [`./internal/EGM.md`](./internal/EGM.md) -
  Implements configuration schema parsing, TUI form prompting, Chezmoi staging
  directory preparation, and template application.

## Interface

- [`./cmd/EGM.md`](./cmd/EGM.md): `setup-workstation` binary (`-c`/`--config`,
  `-d`/`--directory`, `-n`/`--needs-setup`, `-r`/`--reset`; `SETUP_CONFIG`,
  `SETUP_DIRECTORY`).
- [`./internal/EGM.md`](./internal/EGM.md): `setup.Run`, `setup.IsDone`,
  `setup.CheckRunnable`, `setup.Options`, `setup.Config`, and `setup.Shell`.

## Invariants

- Requires both the YAML schema (`/google/etc/setup-workstation.yaml` by
  default) and non-empty template directory (`/google/etc/setup-workstation.d`
  by default) to exist before running.
- Tracks completion state at `$XDG_STATE_HOME/setup-workstation-done` (or
  `~/.local/state/setup-workstation-done`) and stores user answers in
  `~/.config/chezmoi/chezmoi.yaml` (`0600`).

## Side Effects

- Prompts users interactively on the terminal, writes
  `~/.config/chezmoi/chezmoi.yaml`, executes `chezmoi apply` to hydrate
  dotfiles into `$HOME`, and records completion state in
  `$XDG_STATE_HOME/setup-workstation-done`.
