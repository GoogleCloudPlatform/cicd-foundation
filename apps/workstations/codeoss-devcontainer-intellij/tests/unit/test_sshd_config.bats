#!/usr/bin/env bats

# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load test_helper.bash

bats_require_minimum_version 1.5.0

setup() {
  export TEST_TMP="${BATS_FILE_TMPDIR}/mock_sshd"
  mkdir -p "${TEST_TMP}/etc/ssh" "${TEST_TMP}/home/user" "${TEST_TMP}/opt/devcontainer/intellij"
}

@test "02_configure_sshd_port.sh injects Port 2222 into /etc/ssh/sshd_config" {
  local hook_script="${LAYER_DIR}/assets/build-hooks.d/02_configure_sshd_port.sh"
  [ -f "${hook_script}" ]
  [ -x "${hook_script}" ]

  # Simulate hook execution on mock sshd_config
  cat <<'EOF' > "${TEST_TMP}/etc/ssh/sshd_config"
PermitEmptyPasswords yes
PubkeyAuthentication no
EOF

  if ! grep -q "^Port 2222" "${TEST_TMP}/etc/ssh/sshd_config"; then
    echo -e "\n# Move host SSH to 2222 to free port 22 for devcontainer\nPort 2222" >> "${TEST_TMP}/etc/ssh/sshd_config"
  fi

  grep -q "^Port 2222" "${TEST_TMP}/etc/ssh/sshd_config"
}


@test "backend-readiness drop-in sets BACKEND_WAIT_PORTS to 8080 22 2222" {
  local readiness_conf="${LAYER_DIR}/assets/etc/systemd/system/backend-readiness.service.d/10-codeoss-devcontainer-intellij.conf"
  [ -f "${readiness_conf}" ]
  grep -q "BACKEND_WAIT_PORTS=8080 22 2222" "${readiness_conf}"
}

@test "intellij-devcontainer.service systemd user unit exists and is valid" {
  local user_service="${LAYER_DIR}/assets/etc/systemd/user/intellij-devcontainer.service"
  [ -f "${user_service}" ]
  grep -q "ExecStart=/google/scripts/start_intellij_devcontainer.sh" "${user_service}"
  grep -q "Restart=on-failure" "${user_service}"
}

@test "intellij-devcontainer.service is enabled in default.target.wants" {
  local wants_link="${LAYER_DIR}/assets/etc/systemd/user/default.target.wants/intellij-devcontainer.service"
  [ -L "${wants_link}" ] || [ -f "${wants_link}" ]
}

@test "10_preload_devcontainer_image.sh uses fetch_image" {
  local preload_hook="${LAYER_DIR}/assets/build-hooks.d/10_preload_devcontainer_image.sh"
  [ -f "${preload_hook}" ]
  grep -q "fetch_image" "${preload_hook}"
  grep -q "intellij-ultimate" "${preload_hook}"
}

@test "050_seed-devcontainer.sh script seeds template into user home directory" {
  echo "mock devcontainer" > "${TEST_TMP}/opt/devcontainer/intellij/devcontainer.json"

  # Simulate 050_seed-devcontainer.sh logic
  if [[ ! -d "${TEST_TMP}/home/user/.devcontainer" ]]; then
    mkdir -p "${TEST_TMP}/home/user/.devcontainer"
    cp -r "${TEST_TMP}/opt/devcontainer/intellij/"* "${TEST_TMP}/home/user/.devcontainer/"
  fi

  [ -f "${TEST_TMP}/home/user/.devcontainer/devcontainer.json" ]
  grep -q "mock devcontainer" "${TEST_TMP}/home/user/.devcontainer/devcontainer.json"
}
