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

# Common System Configuration (`etc`)

## Overview

System configuration files and boot-time hooks under `/etc` for the `common`
base Cloud Workstation layer, including Docker daemon defaults
(`docker/daemon.json`), systemd units (`systemd/system`,
`systemd/logind.conf.d`), and container runtime startup hooks
(`workstation-startup.d`).

## Subdirectories & Boundaries

- **Workstation Startup Hooks**:
  [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md) -
  Prepares the Docker-in-Docker (`DinD`) runtime environment (`ulimits`,
  `securityfs`, `iptables-legacy`, `/dev/loop*`, cgroup v2 nesting, and NVIDIA
  CDI) via `000_configure-docker.sh`.

## Interface

- [`./workstation-startup.d/EGM.md`](./workstation-startup.d/EGM.md):
  `000_configure-docker.sh` (`fix_ulimits`, `prepare_dind_env`,
  `configure_nvidia`, `main`).

## Invariants

- Startup hooks execute prior to `docker.service` launch and gracefully
  tolerate restricted kernel environments without aborting workstation boot.

## Side Effects

- Configures kernel mounts (`securityfs`), loopback device nodes
  (`/dev/loop0`..`/dev/loop3`), cgroup v2 hierarchies, `iptables-legacy`
  alternatives, and NVIDIA container runtime specs (`/etc/cdi/nvidia.yaml`).
