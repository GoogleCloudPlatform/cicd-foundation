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

# Preflight System Configuration (`etc`)

## Overview

System configuration files under `/etc` for the `preflight` Cloud Workstation
layer, including the Nginx reverse-proxy template
(`nginx/sites-available/default.template`), interactive shell onboarding hook
(`profile.d/99-setup-workstation.sh`), systemd readiness and config-rendering
service definitions (`systemd/system`), and desktop autostart entry
(`xdg/autostart/setup-workstation.desktop`).

## Subdirectories & Boundaries

- **Profile Scripts**: [`./profile.d/EGM.md`](./profile.d/EGM.md) - Triggers
  `/google/bin/setup-workstation` on interactive shell login when initial
  setup is pending (`99-setup-workstation.sh`).

## Interface

- [`./profile.d/EGM.md`](./profile.d/EGM.md): `99-setup-workstation.sh`.

## Invariants

- Interactive shell setup checks only run when `[[ $- == *i* ]]` and
  `/google/etc/setup-workstation.yaml` exists.

## Side Effects

- Launches `/google/bin/setup-workstation` in interactive shells when
  `--needs-setup` returns `0` and provides Nginx/systemd configuration
  templates.
