#!/bin/bash

#
# Copyright 2022-2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Startup script to configure the environment for Docker-in-Docker.

set -euo pipefail

# Workaround for Docker 25+ file descriptor limit issues.
fix_ulimits() {
  # https://github.com/docker/cli/issues/4807
  sed -i 's/ulimit -Hn 524288/# ulimit -Hn 524288/g' /etc/init.d/docker
}

# Performs essential mounts and system configuration for DinD.
prepare_dind_env() {
  # 1. securityfs
  if [[ -d /sys/kernel/security ]] && ! mountpoint -q /sys/kernel/security; then
    mount -t securityfs none /sys/kernel/security || echo "Warning: Could not mount /sys/kernel/security"
  fi

  # 2. iptables legacy for Docker compatibility
  update-alternatives --set iptables /usr/sbin/iptables-legacy

  # 3. Ensure loopback devices (min 4)
  local i
  for i in {0..3}; do
    if [[ ! -b "/dev/loop${i}" ]]; then
      mknod -m660 "/dev/loop${i}" b 7 "${i}" || true
    fi
  done

  # 4. cgroup v2 nesting
  if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
    mkdir -p /sys/fs/cgroup/init
    xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || :
    sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control || :
  fi
}

# Configures NVIDIA Container Toolkit if hardware is present.
configure_nvidia() {
  if [[ -e "/dev/nvidia0" ]]; then
    echo "Configuring docker for nvidia-container-toolkit"
    nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --library-search-path=/var/lib/nvidia/lib64 --dev-root=/ --driver-root=/var/lib/nvidia
    nvidia-ctk runtime configure --runtime=docker
    nvidia-ctk config --in-place --set nvidia-container-runtime.mode=cdi
  fi
}

main() {
  fix_ulimits
  prepare_dind_env
  configure_nvidia

  # Note: Docker daemon itself is managed by systemd (docker.service).
}

main "$@"
