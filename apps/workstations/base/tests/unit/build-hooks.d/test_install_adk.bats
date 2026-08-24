#!/usr/bin/env bats

load ../test_helper.bash

setup() {
  # Mock external commands
  pipx() { echo "MOCK_PIPX: $*"; }
  mkdir() { echo "MOCK_MKDIR: $*"; }
  git() { echo "MOCK_GIT: $*"; }
  curl() { echo "MOCK_CURL: $*"; }
  tar() { echo "MOCK_TAR: $*"; }
  rm() { echo "MOCK_RM: $*"; }
  export -f pipx mkdir git curl tar rm

  # source the script
  # shellcheck source=/dev/null
  source "${HOOKS_DIR}/05_install_adk.sh"
}

@test "05_install_adk.sh installs google-adk when enabled is true" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="true"
  run install_adk
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installing Agent Development Kit" ]]
  [[ "$output" =~ "MOCK_MKDIR" ]]
  [[ "$output" =~ "MOCK_CURL" ]]
}

@test "05_install_adk.sh skips installation when enabled is false" {
  export INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON="false"
  run install_adk
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Installing Agent Development Kit" ]]
  [[ ! "$output" =~ "MOCK_MKDIR" ]]
}
