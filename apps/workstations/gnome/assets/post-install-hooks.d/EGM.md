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

# GNOME Post-Install Hooks (`post-install-hooks.d`)

## Overview

Post-install build hook (`15_patch_chrome_desktop.sh`) for the GNOME workstation
image layer that rewrites `/usr/share/applications/google-chrome.desktop` to
invoke the `/usr/local/bin/google-chrome-stable` wrapper script and registers
Google Chrome as a high-priority pinned dock favorite without autostart.

## Interface

- `15_patch_chrome_desktop.sh`: Executable post-install hook invoked by
  `/google/scripts/build/configure_workstation.sh` via `run_hooks`.
- `DESKTOP_FILE`: Global variable set to
  `/usr/share/applications/google-chrome.desktop`.

## Invariants

- Executes under strict shell mode (`set -euo pipefail`).
- Guards modifications on `[[ -f "${DESKTOP_FILE}" ]]`; if
  `/usr/share/applications/google-chrome.desktop` is absent, logs a warning
  and exits `0` without failing the build.
- Requires `/google/scripts/build/desktop_integration.sh` (providing
  `desktop_register_app`) to exist in the container filesystem when
  `${DESKTOP_FILE}` is present.
- Assigns Google Chrome priority `20` (`X-Workstation-Favorite-Priority=20`),
  `autostart=false` (`X-GNOME-Autostart-enabled=false`), and `favorite=true`
  (`X-Workstation-Favorite=true`) so it appears before IDEs (priority `30`) in
  the GNOME dock.

## Side Effects

- Mutates `/usr/share/applications/google-chrome.desktop` in-place with `sed
-i` to replace `^Exec=/usr/bin/google-chrome-stable` with
  `Exec=/usr/local/bin/google-chrome-stable`.
- Sources `/google/scripts/build/desktop_integration.sh` and invokes
  `desktop_register_app`, updating `[Desktop Entry]` metadata keys and setting
  mode `644` on `/usr/share/applications/google-chrome.desktop`.
