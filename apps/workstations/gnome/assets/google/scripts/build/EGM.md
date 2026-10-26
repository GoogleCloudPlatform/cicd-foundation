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

# GNOME Build Scripts (`build`)

## Overview

Contains `desktop_integration.sh`, a build-time Bash utility script for the
GNOME workstation layer that registers `.desktop` application entries with
custom metadata (`X-Workstation-Favorite`, `X-Workstation-Favorite-Priority`,
`X-GNOME-Autostart-enabled`), symlinks autostart applications into
`/etc/xdg/autostart`, generates a GSettings schema override for GNOME Shell dock
favorites, and refreshes GLib schema and desktop databases.

## Interface

- `desktop_register_app <desktop_file_path> [priority=50] [autostart=true]
[favorite=true]`: Validates a `.desktop` file and injects
  `X-Workstation-Favorite-Priority`, `X-Workstation-Favorite`, and
  `X-GNOME-Autostart-enabled` metadata keys under `[Desktop Entry]`.
- `desktop_apply_integration`: Registers `WORKSTATION_DEFAULT_APP` (if set),
  autodiscovers `.desktop` files in `/usr/share/applications` matching
  `Development|IDE|TerminalEmulator|TextEditor` categories, symlinks
  autostart-enabled entries into `/etc/xdg/autostart`, writes
  `/usr/share/glib-2.0/schemas/99-workstation-favorites.gschema.override`, and
  compiles schemas and desktop databases.
- `WORKSTATION_DEFAULT_APP` (environment variable): Optional primary
  application `.desktop` basename registered at priority `30` with
  `autostart=true` and `favorite=true` when
  `/usr/share/applications/${WORKSTATION_DEFAULT_APP}.desktop` exists.
- `desktop_integration.sh` (CLI entrypoint): Invokes
  `desktop_apply_integration` when executed directly (`${BASH_SOURCE[0]} ==
${0}`).

## Invariants

- Enforces strict shell execution mode via `set -euo pipefail`.
- `desktop_register_app` requires the target `.desktop` file to exist and
  contain a `[Desktop Entry]` header, returning exit code `1` otherwise.
- `desktop_register_app` removes any pre-existing
  `X-Workstation-Favorite-Priority=`, `X-Workstation-Favorite=`, and
  `X-GNOME-Autostart-enabled=` lines before inserting new keys to prevent
  duplicates, and sets file permissions to `644`.
- When `WORKSTATION_DEFAULT_APP` matches an existing `.desktop` file in
  `/usr/share/applications`, it is registered at priority `30` with
  `autostart=true` and `favorite=true` before category autodiscovery runs.
- Autodiscovery only registers `.desktop` files in `Development`, `IDE`,
  `TerminalEmulator`, or `TextEditor` categories that do not already define
  `X-Workstation-Favorite=`, assigning `autostart=false`, `favorite=true`, and
  sequential priorities starting at `40`.
- Dock favorites written to `99-workstation-favorites.gschema.override` are
  sorted numerically by `X-Workstation-Favorite-Priority` (defaulting to `50`)
  and applied to both `[org.gnome.shell]` and `[org.gnome.shell:ubuntu]`.

## Side Effects

- Mutates `.desktop` files in `/usr/share/applications` (or paths passed to
  `desktop_register_app`) in-place via `sed -i` and sets their mode to `644`
  via `chmod`.
- Creates `/etc/xdg/autostart` (`mkdir -p`) and creates symbolic links (`ln
-sf`) for all `.desktop` files in `/usr/share/applications` with
  `X-GNOME-Autostart-enabled=true`.
- Creates and removes a temporary file via `mktemp` and `rm -f` during
  favorite app sorting.
- Writes
  `/usr/share/glib-2.0/schemas/99-workstation-favorites.gschema.override` when
  one or more favorite applications are registered.
- Runs `glib-compile-schemas /usr/share/glib-2.0/schemas` (if the directory
  exists) and `update-desktop-database /usr/share/applications` (if available
  in `PATH`).
