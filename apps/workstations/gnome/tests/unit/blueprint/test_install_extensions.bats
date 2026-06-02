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
  # Mock dependencies
  mkdir -p /tmp/mock-extensions
  export MOCK_EXT_DIR="${BATS_FILE_TMPDIR}/extensions"
  export MOCK_SCHEMA_DIR="${BATS_FILE_TMPDIR}/schemas"
  mkdir -p "${MOCK_EXT_DIR}" "${MOCK_SCHEMA_DIR}"

  # Mock curl to "download" a mock zip
  curl() {
    echo "MOCK_CURL: $*"
    # Create a placeholder file if -o is provided
    local i
    for ((i=1; i<=$#; i++)); do
      if [[ "${!i}" == "-o" ]]; then
        local next=$((i+1))
        touch "${!next}"
      fi
    done
    return 0
  }

  # Mock unzip to create placeholder files
  unzip() {
    echo "MOCK_UNZIP: $*"
    # Find the target directory (-d)
    local i
    for ((i=1; i<=$#; i++)); do
      if [[ "${!i}" == "-d" ]]; then
        local next=$((i+1))
        mkdir -p "${!next}/schemas"
        touch "${!next}/schemas/test.gschema.xml"
      fi
    done
  }

  # Mock glib-compile-schemas
  glib-compile-schemas() {
    echo "MOCK_GLIB_COMPILE: $*"
  }

  export -f curl unzip glib-compile-schemas
}

@test "01_install_gnome_extensions.sh installs multiple extensions" {
  # Override system paths for testing
  export GNOME_SHELL_EXTENSIONS="ext1@example.com:123 ext2@example.com:456"

  local test_script="${BATS_FILE_TMPDIR}/test_install.sh"
  cp "${HOOKS_DIR}/01_install_gnome_extensions.sh" "${test_script}"
  sed -i "s|/usr/share/gnome-shell/extensions|${MOCK_EXT_DIR}|g" "${test_script}"
  sed -i "s|/usr/share/glib-2.0/schemas|${MOCK_SCHEMA_DIR}|g" "${test_script}"

  # Also mock mkdir to not fail if it tries to create system dirs (though sed should have caught it)
  mkdir() {
    if [[ "$*" == *"/usr/share"* ]]; then
      echo "MOCK_MKDIR: $*"
      return 0
    fi
    command mkdir "$@"
  }
  export -f mkdir

  run bash "${test_script}"

  echo "DEBUG OUTPUT: ${output}"
  ls -R "${MOCK_EXT_DIR}"
  ls -R "${MOCK_SCHEMA_DIR}"

  [ "$status" -eq 0 ]
  [[ "$output" == *'Downloading GNOME extension: ext1@example.com (version 123) from https://extensions.gnome.org/extension-data/ext1example.com.v123.shell-extension.zip'* ]]
  [[ "$output" == *'Downloading GNOME extension: ext2@example.com (version 456) from https://extensions.gnome.org/extension-data/ext2example.com.v456.shell-extension.zip'* ]]
  [[ "$output" =~ "compiling local schemas and copying to system schemas directory" ]]
  [[ "$output" =~ "Re-compiling glib schemas" ]]

  # Verify files were "installed"
  [ -d "${MOCK_EXT_DIR}/ext1@example.com" ]
  [ -d "${MOCK_EXT_DIR}/ext2@example.com" ]
  [ -f "${MOCK_SCHEMA_DIR}/test.gschema.xml" ]
}

@test "01_install_gnome_extensions.sh handles empty extensions list" {
  export GNOME_SHELL_EXTENSIONS=""
  run bash "${HOOKS_DIR}/01_install_gnome_extensions.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No GNOME extensions to install" ]]
}
