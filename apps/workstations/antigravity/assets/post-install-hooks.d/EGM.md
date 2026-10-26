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

# Antigravity Post-Install Hooks (`post-install-hooks.d`)

## Overview

Contains the post-install build hook (`10_patch_antigravity_desktop.sh`) for the
Antigravity Cloud Workstation layer, which patches the installed Antigravity
`.desktop` entry to invoke the `/usr/local/bin/antigravity` GPU/Wayland
stability wrapper and registers the application for GNOME dock pinning and
session autostart.

## Interface

- `10_patch_antigravity_desktop.sh`: Executable Bash post-install hook invoked
  by `/google/scripts/build/configure_workstation.sh`.
- `DESKTOP_FILE`: `/usr/share/applications/antigravity.desktop`.
- External dependencies sourced: `/google/scripts/common.sh` (`log`, `warn`,
  `log_event`) and `/google/scripts/build/desktop_integration.sh`
  (`desktop_register_app`).

## Invariants

- Executes with strict Bash error handling (`set -euo pipefail`).
- Requires `/google/scripts/common.sh` to be present and sourceable.
- Idempotent/safe when `/usr/share/applications/antigravity.desktop` is absent
  (logs a warning and exits cleanly without failing the build).
- When `/usr/share/applications/antigravity.desktop` exists,
  `/google/scripts/build/desktop_integration.sh` must be present and define
  `desktop_register_app`.

## Side Effects

- Mutates `/usr/share/applications/antigravity.desktop` in-place via `sed -i`,
  replacing `^Exec=/usr/share/antigravity/antigravity` with
  `Exec=/usr/local/bin/antigravity`.
- Calls `desktop_register_app "/usr/share/applications/antigravity.desktop" 10
true true` to register Antigravity as a priority-10 GNOME dock favorite and
  enable XDG autostart.
- Emits build logs (`log`, `warn`) and a structured event (`log_event
BUILD_HOOK_COMPLETED ... HOOK=patch-antigravity`).
