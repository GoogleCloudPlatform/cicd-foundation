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

# GNOME System Configuration (`etc`)

## Overview

System configuration files under `/etc` for the `gnome` Cloud Workstation layer,
including APT keyrings/sources (`apt`), dconf defaults (`dconf`), Guacamole user
mapping templates (`guacamole`), Chrome policies (`opt/chrome`), Polkit rules
(`polkit-1`), shell profile hooks (`profile.d`), and systemd service definitions
(`systemd`).

## Subdirectories & Boundaries

- **Profile Scripts**: [`./profile.d/EGM.md`](./profile.d/EGM.md) - Appends
  `/google/bin` to `PATH` via `google-bin.sh`.

## Interface

- [`./profile.d/EGM.md`](./profile.d/EGM.md): `google-bin.sh` (`PATH`).

## Invariants

- Ensures `/google/bin` is idempotently included in interactive shell `PATH`
  environments.

## Side Effects

- Updates interactive shell `PATH` variables and provides systemd, dconf,
  Polkit, and Guacamole system configurations.
