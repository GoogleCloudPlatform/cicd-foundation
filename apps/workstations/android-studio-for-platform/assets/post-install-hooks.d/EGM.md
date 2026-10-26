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

# ASfP Post-Install Hooks (`post-install-hooks.d`)

## Overview

Post-install build hooks for the Android Studio for Platform (`ASFP` / `ASfP`)
workstation image layer that install Cuttlefish Debian packages and legacy AOSP
(Android Open Source Project) library symlinks, and patch the ASfP desktop entry
to use the `/usr/local/bin/asfp-studio` wrapper and `jetbrains-studio`
`StartupWMClass`.

## Interface

- `10_install_aosp_tooling.sh`: `install_aosp_tooling()`, `main()`, and
  environment variable `APT_OPTS` (optional, defaults to `-y
--no-install-recommends`).
- `20_patch_asfp_desktop.sh`: `DESKTOP_FILE`
  (`/usr/share/applications/asfp-canary.desktop`), `patch_asfp_desktop()`, and
  `main()`.

## Invariants

- Both scripts execute under bash with strict error handling (`set -euo
pipefail`) and source `/google/scripts/common.sh`.
- Both scripts guard direct execution via `[[ "${BASH_SOURCE[0]}" == "${0}"
]]` before invoking `main "$@"`.
- `10_install_aosp_tooling.sh` requires `/cuttlefish` to exist and contain
  matching `./cuttlefish-base_*.deb` and `./cuttlefish-user_*.deb` packages.
- `20_patch_asfp_desktop.sh` only modifies
  `/usr/share/applications/asfp-canary.desktop` if the file exists (otherwise
  logging a warning), and only rewrites `Exec=` to
  `/usr/local/bin/asfp-studio` if `/usr/local/bin/asfp-studio` exists.
- `20_patch_asfp_desktop.sh` ensures `StartupWMClass=jetbrains-studio` is set
  in `/usr/share/applications/asfp-canary.desktop` if not already present.

## Side Effects

- `10_install_aosp_tooling.sh`: Installs `./cuttlefish-base_*.deb` and
  `./cuttlefish-user_*.deb` from `/cuttlefish` via `apt-get install`.
- `10_install_aosp_tooling.sh`: Creates/overwrites symlinks
  `/usr/lib/x86_64-linux-gnu/libncurses.so.5` -> `libncurses.so.6` and
  `/usr/lib/x86_64-linux-gnu/libtinfo.so.5` -> `libtinfo.so.6`.
- `10_install_aosp_tooling.sh`: Recursively deletes the `/cuttlefish`
  directory (`rm -rf /cuttlefish`).
- `20_patch_asfp_desktop.sh`: Sets permissions `755` (`chmod 755`) on
  `/usr/local/bin/asfp-studio` if present.
- `20_patch_asfp_desktop.sh`: Modifies
  `/usr/share/applications/asfp-canary.desktop` in-place (`sed -i`) to set
  `Exec=/usr/local/bin/asfp-studio` and `StartupWMClass=jetbrains-studio`.
- `20_patch_asfp_desktop.sh`: Emits build logs and a `BUILD_HOOK_COMPLETED`
  event via helper functions from `/google/scripts/common.sh`.
