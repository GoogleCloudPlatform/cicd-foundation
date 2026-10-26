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

# SRE Persona Scripts (`persona-sre/scripts`)

## Overview

Provides operational automation scripts for managing Cloud Workstation instance
lifecycle transitions, SSH/TCP tunneling, Cloud Build execution and monitoring,
and live user-session D-Bus command execution.

## Interface

- `dbus_session_cmd.sh [COMMAND]`: Entrypoint script (`usage()`, `main()`)
  that executes a shell command inside UID `1000`'s active D-Bus session.
- `manage_workstation.sh [start|stop|restart|status|wait|ssh|tunnel]
[WORKSTATION]
[--target-state|--project|--cluster|--config|--region|--timeout|--local-port|--remote-port|--user|--browser|--no-ssh-config]`:
  Entrypoint script (`usage()`, `get_cws_host()`, `open_browser_url()`,
  `wait_for_cws_state()`, `start_cws()`, `stop_cws()`, `status_cws()`,
  `tunnel_cws()`, `ssh_cws()`, `main()`) for workstation state management and
  connectivity.
- `monitor_build.sh [BUILD_ID] [--latest] [--project] [--region] [--lookback]
[--interval] [--help]`: Entrypoint script (`usage()`, `manage_cws()`,
  `main()`) that polls Cloud Build status until completion.
- `trigger_build.py [image_path] [--service-account] [--dry-run]`: Python CLI
  (`log(msg)`, `warn(msg)`, `error(msg)`, `run_command(cmd, capture_output)`,
  `get_env_vars()`, `adapt_config(trigger_json)`,
  `filter_substitutions(substitutions, build_config)`, `main()`) that adapts
  Cloud Build trigger definitions and submits image builds.

## Invariants

- All Bash scripts (`dbus_session_cmd.sh`, `manage_workstation.sh`,
  `monitor_build.sh`) enforce strict mode (`set -euo pipefail`);
  `dbus_session_cmd.sh` and `monitor_build.sh` require `../../common.sh`, while
  `manage_workstation.sh` sources `../../common.sh` when present and falls back
  to inline `log`/`warn`/`error` functions and `CWS_NAME` /
  `GOOGLE_CLOUD_PROJECT` / `CWS_CLUSTER` / `CWS_CONFIG` / `CWS_REGION` /
  `CWS_LOCAL_PORT` / `BROWSER` environment variables when downloaded standalone.
- `dbus_session_cmd.sh` requires at least one argument and sets
  `XDG_RUNTIME_DIR=/run/user/1000` and
  `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus` for user `user`.
- `manage_workstation.sh`: Requires `gcloud` in `PATH` and non-empty
  `workstation`, `project`, `cluster`, `config`, and `region` values across all
  lifecycle actions (`start`, `stop`, `restart`, `status`, `wait`, `ssh`,
  `tunnel`). `wait_for_cws_state` polls every 10s until `target_state` is
  reached or `timeout_seconds` (default 600s) expires; `start_cws` skips
  starting if the workstation is already in `STATE_RUNNING`.
- `monitor_build.sh` requires `project` (`GOOGLE_CLOUD_PROJECT` or `--project`)
  and `region` (`BUILD_REGION`, `CWS_REGION`, or `--region`) and a valid
  `build_id` (explicit, latest, or created within `lookback` minutes, default
  10m), polling every `interval` seconds (default 30s) until status matches
  `^(SUCCESS|FAILURE|CANCELLED|TIMEOUT)$` and exiting non-zero if `status !=
SUCCESS`.
- `trigger_build.py` requires `image_path` (default
  `'apps/workstations/gnome'`) to be an existing directory containing a
  `Dockerfile`, and requires `GOOGLE_CLOUD_PROJECT` and `BUILD_REGION` (or
  `CWS_REGION`) to be set in the environment or repository root `.env` (system
  environment variables take precedence).
- `trigger_build.py`: `adapt_config` requires a non-empty `'build'` object in
  `trigger_json`, strips the `'clone'` step and any `waitFor` references to
  `'clone'`, and defaults `timeout` to `'7200s'`; `filter_substitutions`
  retains only substitution keys referenced in the serialized build config.
  When `gcloud builds triggers describe <image_name>` fails, `main()`
  synthesizes a fallback inline `gcr.io/k8s-skaffold/skaffold:v2.18.1` build
  config (`E2_HIGHCPU_32`, `CLOUD_LOGGING_ONLY`, `7200s` timeout,
  `_SKAFFOLD_DEFAULT_REPO =
"<ARTIFACT_REGION_or_BUILD_REGION>-docker.pkg.dev/<project>/cicd-foundation"`)
  and defaults the service account to
  `projects/<project>/serviceAccounts/cloudbuild@<project>.iam.gserviceaccount.com`.

## Side Effects

- `dbus_session_cmd.sh` executes commands as user `user` (UID `1000`) via
  `sudo -u user bash -c`.
- `manage_workstation.sh` invokes `gcloud workstations` CLI commands
  (`describe`, `start`, `stop`, `start-tcp-tunnel`, `ssh`) to inspect or
  mutate Cloud Workstation state and open SSH/TCP tunnel sessions.
- `manage_workstation.sh` optionally opens `https://<cws_host>` in a local web
  browser and appends a `Host cws` block (`127.0.0.1:<local_port>`) to
  `$HOME/.ssh/config` when tunneling unless `--no-ssh-config` is passed.
- `monitor_build.sh` queries Cloud Build state via `gcloud builds list` and
  `gcloud builds describe` and, on build `SUCCESS`, invokes
  `manage_workstation.sh start` if `CWS_NAME`, `CWS_CLUSTER`, and `CWS_CONFIG`
  are set.
- `trigger_build.py` reads `<repo_root>/.env`, queries trigger definitions via
  `gcloud builds triggers describe` (falling back to an inline Skaffold build
  config if not found), writes the adapted build configuration to a temporary
  JSON file (`tempfile.NamedTemporaryFile` with `delete=False`), submits
  builds via `gcloud builds submit` (unless `--dry-run` is specified), and
  unlinks the temporary file in a `finally` block (`os.unlink`).
