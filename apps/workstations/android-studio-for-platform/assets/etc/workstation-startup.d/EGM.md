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

# ASfP Workstation Startup Scripts (`workstation-startup.d`)

## Overview

Workstation startup scripts in `/etc/workstation-startup.d` for the Android
Studio for Platform (`ASFP` / `ASfP`) image layer that configure runtime user
group memberships for Cuttlefish virtualization and hardware rendering
(`011_add-cuttlefish-groups.sh`), tune ASfP JVM heap and IntelliSense limits in
`studio64.vmoptions`, and remove stale IDE lock files
(`200_add-asfp-defaults.sh`).

## Interface

- `011_add-cuttlefish-groups.sh`: Startup script that appends `user` to `kvm`,
  `cvdnetwork`, and `render` groups.
- `200_add-asfp-defaults.sh`: Startup script defining
  `getSeventyPercentOfMemory()` to compute 70% of available system RAM (in MB,
  truncated to 100 MB increments) and patch
  `/opt/android-studio-for-platform-canary/bin/studio64.vmoptions`.

## Invariants

- `011_add-cuttlefish-groups.sh`: Each target group (`kvm`, `cvdnetwork`,
  `render`) is verified to exist via `getent group` before invoking `usermod`,
  and modifications exclusively target the `user` account.
- `200_add-asfp-defaults.sh`: JVM maximum heap size (`-Xmx`) in
  `/opt/android-studio-for-platform-canary/bin/studio64.vmoptions` is set to
  70% of available system memory (`vm_memory`) capped at a maximum of `64000m`
  (`-Xmx64000m`), and `-Didea.max.intellisense.filesize` is set to `10000`.

## Side Effects

- `011_add-cuttlefish-groups.sh`: Writes status output to stdout and modifies
  `/etc/group` and `/etc/gshadow` by appending `user` to `kvm`, `cvdnetwork`,
  and `render` via `usermod -aG`.
- `200_add-asfp-defaults.sh`: Modifies
  `/opt/android-studio-for-platform-canary/bin/studio64.vmoptions` in-place
  via `sed -i` and deletes stale `.lock` files matching
  `${HOME}/.config/Google/*/AndroidStudioForPlatform*/.lock`.
