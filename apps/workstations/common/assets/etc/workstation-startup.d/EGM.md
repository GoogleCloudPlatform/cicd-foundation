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

# Common Workstation Startup Hooks (`workstation-startup.d`)

## Overview

Startup hook directory `/etc/workstation-startup.d` in the `common` workstation
layer containing `000_configure-docker.sh`, which prepares the container runtime
environment (`ulimits`, `securityfs`, `iptables-legacy`, loopback devices,
cgroup v2 nesting, and NVIDIA Container Toolkit) for Docker-in-Docker (`DinD`)
before systemd starts `docker.service`.

## Interface

- `000_configure-docker.sh`: Startup hook script executed during workstation
  initialization (via `run_hooks "/etc/workstation-startup.d"` or
  `/usr/bin/workstation-startup`).
- `fix_ulimits()`: Comments out `ulimit -Hn 524288` in `/etc/init.d/docker` to
  work around Docker 25+ file descriptor limit issues.
- `prepare_dind_env()`: Configures kernel `securityfs` mount,
  `iptables-legacy` alternative, `/dev/loop0`..`/dev/loop3` block devices, and
  cgroup v2 nesting.
- `configure_nvidia()`: Configures Docker runtime and CDI specification via
  `nvidia-ctk` when `/dev/nvidia0` is present.
- `main("$@")`: Entrypoint invoking `fix_ulimits`, `prepare_dind_env`, and
  `configure_nvidia`.

## Invariants

- Executes under strict shell options (`set -euo pipefail`).
- Privileged host/kernel operations in `prepare_dind_env` (mounting
  `/sys/kernel/security`, setting `iptables-legacy`, creating `/dev/loop*`
  nodes, and migrating cgroup v2 procs/controllers) suppress non-zero exit
  codes so restricted environments do not abort startup.
- Ensures at least 4 loopback block devices (`/dev/loop0` through
  `/dev/loop3`, major `7`, minor `0-3`, mode `660`) exist.
- NVIDIA configuration (`nvidia-ctk`) executes only if `/dev/nvidia0` exists.
- Does not start `dockerd` directly; the Docker daemon lifecycle is delegated
  to systemd (`docker.service`).

## Side Effects

- Modifies `/etc/init.d/docker` in-place with `sed -i` to comment out `ulimit
-Hn 524288` if `/etc/init.d/docker` exists.
- Mounts `securityfs` onto `/sys/kernel/security` if the directory exists and
  is not already mounted.
- Switches the `iptables` alternative to `/usr/sbin/iptables-legacy` via
  `update-alternatives` if available.
- Creates block device nodes `/dev/loop0`..`/dev/loop3` via `mknod` if
  missing.
- Creates `/sys/fs/cgroup/init`, moves PIDs from `/sys/fs/cgroup/cgroup.procs`
  to `/sys/fs/cgroup/init/cgroup.procs`, and writes controller enablement
  flags to `/sys/fs/cgroup/cgroup.subtree_control` when cgroup v2
  (`/sys/fs/cgroup/cgroup.controllers`) is present.
- Generates `/etc/cdi/nvidia.yaml` and updates Docker and
  `nvidia-container-runtime` configurations in-place via `nvidia-ctk` when
  `/dev/nvidia0` is present.
