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

# Preflight Profile Scripts (`profile.d`)

## Overview

Shell profile script (`99-setup-workstation.sh`) in `/etc/profile.d` that
automatically runs `/google/bin/setup-workstation` on interactive shell startup
when a workstation setup configuration exists and setup has not yet been
completed.

## Interface

- `99-setup-workstation.sh`: Sourced from `/etc/profile.d` (exports no symbols
  or functions).

## Invariants

- Only executes setup checks if the shell is interactive (`[[ $- == *i* ]]`).
- Requires `/google/etc/setup-workstation.yaml` to exist as a regular file
  (`-f`) and `/google/bin/setup-workstation --needs-setup` to return exit code
  `0` before invoking setup.

## Side Effects

- Executes `/google/bin/setup-workstation --needs-setup 2>/dev/null` to check
  if initial workstation setup is needed.
- Executes `/google/bin/setup-workstation` in the current interactive shell
  session when setup is required.
