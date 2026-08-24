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

# shellcheck disable=SC2329

load ../test_helper.bash

setup() {
  export CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"
  # Mock external commands
  curl() {
    echo "MOCK_CURL: $*"
    # find the output file and touch it
    local i=0
    for arg in "$@"; do
      if [[ "$arg" == "-o" ]]; then
        touch "${@:i+2:1}"
      fi
      i=$((i+1))
    done
  }
  sha256sum() {
    if [[ "$1" == "-c" ]]; then
      echo "MOCK_SHA256SUM: Checking hash"
      # just consume the input and exit successfully
      cat > /dev/null
      return 0
    else
      echo "MOCK_SHA256SUM: Calculating hash"
      # return a dummy hash
      echo "dummyhash  -"
    fi
  }
  tar() { echo "MOCK_TAR: $*"; }
  mv() { echo "MOCK_MV: $*"; }
  ln() { echo "MOCK_LN: $*"; }
  rm() { echo "MOCK_RM: $*"; }
  export -f curl sha256sum tar mv ln rm

  # Source the script under test
  # shellcheck source=apps/workstations/base/assets/google/scripts/build/install_functions.sh
  source "${SCRIPTS_DIR}/build/install_functions.sh"
}

@test "download_and_validate calls curl and sha256sum with correct arguments" {
  run download_and_validate "http://example.com/file.tar.gz" "12345" "${BATS_TEST_TMPDIR}/file.tar.gz"

  [ "$status" -eq 0 ]
  [[ "$output" == *"MOCK_CURL:"* ]]
  [[ "$output" == *"-o ${BATS_TEST_TMPDIR}/file.tar.gz"* ]]
  [[ "$output" == *"http://example.com/file.tar.gz"* ]]
  [[ "$output" == *"MOCK_SHA256SUM: Checking hash"* ]]
}

@test "install_binary_from_tarball calls all the right commands" {
  run install_binary_from_tarball "http://example.com/file.tar.gz" "12345" "${BATS_TEST_TMPDIR}/file.tar.gz" "file" "/usr/local/bin" "my-file" "my-alias"

  [ "$status" -eq 0 ]
  [[ "$output" == *"MOCK_CURL:"* ]]
  [[ "$output" == *"-o ${BATS_TEST_TMPDIR}/file.tar.gz"* ]]
  [[ "$output" == *"http://example.com/file.tar.gz"* ]]
  [[ "$output" == *"MOCK_SHA256SUM: Checking hash"* ]]
  [[ "$output" == *"MOCK_TAR: -xzf ${BATS_TEST_TMPDIR}/file.tar.gz file"* ]]
  [[ "$output" == *"MOCK_MV: file /usr/local/bin/my-file"* ]]
  [[ "$output" == *"MOCK_LN: -sf my-file /usr/local/bin/my-alias"* ]]
  [[ "$output" == *"MOCK_RM: -f ${BATS_TEST_TMPDIR}/file.tar.gz"* ]]
}
