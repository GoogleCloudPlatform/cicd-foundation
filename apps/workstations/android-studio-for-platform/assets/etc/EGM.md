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

# ASfP System Configuration (`etc`)

## Overview

System configuration files and startup hooks under `/etc` for the Android Studio
for Platform (`ASfP`) workstation image, including APT repository definitions
(`apt/sources.list.d/abfs.list`), sysctl kernel parameters
(`sysctl.d/asfp.conf`), and runtime startup scripts (`workstation-startup.d`).

## Subdirectories & Boundaries

- **Workstation Startup Scripts**:
  [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md) -
  Configures `kvm`, `cvdnetwork`, and `render` group permissions, tunes
  `studio64.vmoptions` memory/IntelliSense settings, and cleans up stale ASfP
  `.lock` files at boot.

## Interface

- [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md):
  `011_add-cuttlefish-groups.sh` and `200_add-asfp-defaults.sh`.

## Invariants

- Startup hooks in `workstation-startup.d` execute in lexical order during
  container startup and cap ASfP JVM heap allocation at 64 GB (`64000m`).

## Side Effects

- Updates system group memberships for `user`, rewrites
  `/opt/android-studio-for-platform-canary/bin/studio64.vmoptions`, and
  removes stale IDE lock files in `${HOME}/.config/Google`.
