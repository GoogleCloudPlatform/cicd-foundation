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

# Site-Reliability Engineer Persona (`persona-sre`)

## Overview

Defines the Site-Reliability Engineer (`persona-sre`) agent skill,
troubleshooting playbooks, and lifecycle automation scripts for managing Cloud
Workstation instances, Cloud Builds, and systemd/D-Bus user sessions.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative SRE persona workflow, Service Level
  Objectives (SLOs), and workstation lifecycle instructions.
- [`references/troubleshooting.md`](./references/troubleshooting.md): Cloud
  Workstations (CWS) troubleshooting playbook covering automated diagnostics,
  systemd cycles, GNOME Shell, and Guacamole/Nginx checks.
- [`scripts`](./scripts/EGM.md): Operational scripts (`dbus_session_cmd.sh`,
  `manage_workstation.sh`, `monitor_build.sh`, `trigger_build.py`) for
  workstation state control, Cloud Build orchestration, and live D-Bus session
  commands.
- `tests/` (`test_manage_workstation.bats`, `test_trigger_build.py`,
  `test_helper.bash`): Bats and Pytest unit test suites exposed via
  `allowed-tools` in [`SKILL.md`](./SKILL.md).

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): CLI automation for Cloud Workstation
  start/stop/wait/SSH/tunnel operations, Cloud Build triggering/polling, and
  UID `1000` D-Bus session execution.
- `tests`: Unit test suites for `manage_workstation.sh` and
  `trigger_build.py`.

## Invariants

- Long-running workstation and Cloud Build operations must be executed through
  the standardized scripts in [`scripts`](./scripts/EGM.md) rather than ad-hoc
  `gcloud` commands.
- Live user-session D-Bus commands must target UID `1000`'s active session bus
  (`unix:path=/run/user/1000/bus`) via `dbus_session_cmd.sh` rather than
  spawning a transient `dbus-run-session`.

## Side Effects

- Scripts in [`scripts`](./scripts/EGM.md) mutate Cloud Workstation instance
  states, submit and poll Cloud Builds via `gcloud`, update
  `$HOME/.ssh/config` during tunneling, and execute commands as UID `1000` via
  `sudo`.
