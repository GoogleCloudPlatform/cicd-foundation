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

# Common Google Scripts (`scripts`)

## Overview

Central runtime boot orchestration, user initialization, shared utility library,
and build-time configuration scripts (`/google/scripts`) for Google Cloud
Workstations container images. Coordinates container entrypoint startup
(`entrypoint.sh`), nftables-based ingress traffic gating (`traffic_control.sh`),
persistent `/etc/machine-id` generation/restoration (`machine_id_setup.sh`),
background `journalctl` streaming to stdout (`cloud_logging_setup.sh`), startup
hook execution and environment propagation into `systemd` (`start_systemd.sh`),
one-time user runtime/home directory and group initialization (`user_setup.sh`),
cached container image loading (`load_cached_images.sh`), shared
logging/retry/GPU-detection/hook utilities (`common.sh`), and build-time
package/asset installation (`./build`).

## Interface

- `common.sh`: Exports `WORKSTATION_USER`, `WORKSTATION_UID`,
  `EPHEMERAL_ENV_DIR`, `EPHEMERAL_ENV_FILENAME`, `EPHEMERAL_ENV_PATH`,
  `RDP_HOST`, `RDP_PORT`, `SSH_HOST`, `SSH_PORT`, `ENABLE_TIGERVNC`,
  `ENABLE_CRD`, `DEFAULT_ENABLE_AUDIO_INPUT`, `DEFAULT_PROTOCOL`,
  `DEFAULT_TIMEOUT_MS`, `WORKSTATION_GPU_ENABLED`, `RETRY_ATTEMPTS`, and
  `RETRY_DELAY`; functions `log(msg)`, `check_file(path)`, `warn(...)`,
  `error(...)`, `retry([attempts, delay,] cmd)`, `run_hooks(hook_dir)`,
  `log_event(event, message, [severity], [KEY=VALUE...])`,
  `wait_for_docker([timeout])`, and `load_cached_images([images_dir])`.
- `entrypoint.sh`: `main(...)`.
- `traffic_control.sh`: `main([block|permit])`, `setup_table()`,
  `block_traffic()`, and `permit_traffic()`.
- `cloud_logging_setup.sh`: `main(...)`.
- `machine_id_setup.sh`: `readonly MACHINE_ID_FILE`
  (`/home/.workstation/machine-id`), exports `MACHINE_ID`, and `main(...)`.
- `start_systemd.sh`: `propagate_env()` and `main(...)`.
- `user_setup.sh`: `setup_runtime_dir()`, `setup_home_dir()`,
  `run_user_setup_hooks()`, and `main(...)`.
- `load_cached_images.sh`: `IMAGES_DIR` (`${1:-/opt/images}`) and `main(...)`.
- **Build Scripts**: [`./build/EGM.md`](./build/EGM.md) -
  `configure_workstation.sh` and `install_functions.sh`.

## Invariants

- All executable scripts (except the sourced library `common.sh`) enforce
  strict bash error handling via `set -euo pipefail`.
- During boot (`entrypoint.sh`), external network traffic is blocked via
  `traffic_control.sh block` (allowing only loopback `lo` traffic and dropping
  all other input packets via `nftables`) before services start, and is only
  permitted once `traffic_control.sh permit` deletes the `inet
workstation_mgmt` table.
- `MACHINE_ID` is persisted across container restarts in
  `/home/.workstation/machine-id`, mirrored to `/etc/machine-id`, and passed
  to `/sbin/init --machine-id` so systemd and desktop services observe a
  consistent machine identity.
- `user_setup.sh` is idempotent per container boot via the
  `/run/user-setup-done` sentinel file and ensures
  `/run/user/${WORKSTATION_UID}` (`XDG_RUNTIME_DIR`) has mode `700` and
  `/home/${WORKSTATION_USER}` ownership is updated without dereferencing
  symlinks (`chown -R -h`).
- `WORKSTATION_GPU_ENABLED` is deterministically set to `true` if `/dev/dri`
  or `/dev/nvidia0` is present at script load time, and `false` otherwise.
- `run_hooks` executes top-level `*.sh` scripts in a target directory in
  sorted lexical order and logs warnings on non-zero exit codes without
  aborting the caller.
- `retry` uses exponential backoff (`current_delay * 2` per failed attempt)
  and terminates execution via `error` (exit code `1`) if all attempts fail.

## Side Effects

- `common.sh` (`log_event`) exports `TS`, `SEV`, `EVT`, `MSG`, `SVC`, and
  `META` environment variables and renders
  `/google/templates/log.json.template` to stdout; `load_cached_images` loads
  `/opt/images/*.tar` archives into the local Docker daemon via `docker load`.
- `traffic_control.sh` creates or deletes the `nftables` table `inet
workstation_mgmt` and its `input` filter chain in the kernel network stack.
- `cloud_logging_setup.sh` spawns a detached background subshell that polls
  `journalctl -n0` and streams `journalctl -f` to stdout.
- `machine_id_setup.sh` reads `/proc/sys/kernel/random/uuid` on first boot and
  creates/overwrites `/home/.workstation/machine-id` and `/etc/machine-id`.
- `start_systemd.sh` deletes `/etc/ssh/sshd_not_to_be_run`, creates
  `/run/sshd` (mode `0755`), generates SSH host keys via `ssh-keygen -A`,
  executes scripts in `/etc/workstation-startup.d`, writes filtered
  environment variables to `/etc/systemd/system.conf.d/10-env.conf`, and
  replaces the current process (`exec`) with `/sbin/init --system
--unit=multi-user.target`.
- `user_setup.sh` creates `/run/user/${WORKSTATION_UID}` (mode `700`), adds
  `${WORKSTATION_USER}` to the `audio` and `docker` groups via `usermod -aG`,
  recursively changes ownership of `/home/${WORKSTATION_USER}`, executes
  scripts in `/google/scripts/user-setup.d`, and creates
  `/run/user-setup-done`.
- `load_cached_images.sh` loads `*.tar` archives from `${IMAGES_DIR}` into the
  Docker daemon via `docker load -i` and tags
  `us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest`
  as `devcontainer-intellij:latest`.
