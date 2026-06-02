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

load ../test_helper.bash

setup() {
  skip_if_slow

  export TEMP_DIR=$(mktemp -d)
  export ETC_MACHINE_ID="${TEMP_DIR}/etc/machine-id"
  export MACHINE_ID_FILE="${TEMP_DIR}/home/.workstation/machine-id"

  mkdir -p "${TEMP_DIR}/home/.workstation"
  mkdir -p "${TEMP_DIR}/etc"

  cp "${SCRIPTS_DIR}/machine_id_setup.sh" "${TEMP_DIR}/test_script.sh"
  cp "${SCRIPTS_DIR}/common.sh" "${TEMP_DIR}/common.sh"

  sed -i "s|/etc/machine-id|${ETC_MACHINE_ID}|g" "${TEMP_DIR}/test_script.sh"
  sed -i "s|/google/scripts/common.sh|${TEMP_DIR}/common.sh|g" "${TEMP_DIR}/test_script.sh"
  sed -i "s|readonly MACHINE_ID_FILE=.*|readonly MACHINE_ID_FILE=\"${MACHINE_ID_FILE}\"|g" "${TEMP_DIR}/test_script.sh"
}

teardown() {
  if [[ -d "${TEMP_DIR:-}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}

@test "first run creates machine-id files and they match" {
  run bash "${TEMP_DIR}/test_script.sh"
  [ "$status" -eq 0 ]
  [ -f "${MACHINE_ID_FILE}" ]
  [ -f "${ETC_MACHINE_ID}" ]

  val1=$(<"${MACHINE_ID_FILE}")
  val2=$(<"${ETC_MACHINE_ID}")
  [ "${val1}" == "${val2}" ]
}

@test "second run restores machine-id after reboot" {
  bash "${TEMP_DIR}/test_script.sh"
  original_val=$(<"${MACHINE_ID_FILE}")

  rm -f "${ETC_MACHINE_ID}"

  run bash "${TEMP_DIR}/test_script.sh"
  [ "$status" -eq 0 ]

  new_val=$(<"${ETC_MACHINE_ID}")
  [ "${original_val}" == "${new_val}" ]
}
