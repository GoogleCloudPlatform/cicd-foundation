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

@test "devcontainer.json exists and is valid JSON" {
  local devcontainer_json="${LAYER_DIR}/.devcontainer/devcontainer.json"
  [ -f "${devcontainer_json}" ]

  if command -v jq >/dev/null 2>&1; then
    run jq . "${devcontainer_json}"
    [ "$status" -eq 0 ]
  fi
}

@test "devcontainer.json exposes port 22 in forwardPorts" {
  local devcontainer_json="${LAYER_DIR}/.devcontainer/devcontainer.json"
  if command -v jq >/dev/null 2>&1; then
    run jq '.forwardPorts[] | select(. == 22)' "${devcontainer_json}"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ 22 ]]
  else
    grep -q '"forwardPorts"' "${devcontainer_json}"
    grep -q '22' "${devcontainer_json}"
  fi
}

@test "Devcontainer Dockerfile uses the IntelliJ Ultimate base image" {
  local devcontainer_dockerfile="${LAYER_DIR}/.devcontainer/Dockerfile"
  [ -f "${devcontainer_dockerfile}" ]
  grep -q "FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest" "${devcontainer_dockerfile}"
}

@test "Devcontainer Dockerfile specifies Antigravity CLI and SDK arguments" {
  local devcontainer_dockerfile="${LAYER_DIR}/.devcontainer/Dockerfile"
  grep -q "ARG ANTIGRAVITY_CLI_VERSION=1.1.22" "${devcontainer_dockerfile}"
  grep -q "ARG ANTIGRAVITY_CLI_SHA256=1e1a219a86e75d7c6351f96d182ca2105302d5c34d8fa9c31265dc0adf24145f" "${devcontainer_dockerfile}"
  grep -q "ARG ANTIGRAVITY_SDK_VERSION=0.1.15" "${devcontainer_dockerfile}"
  grep -q "ARG ANTIGRAVITY_SDK_SHA256=ae307d2fe7643a4d779dcc1160860413b55bfbfe549377e51f7e76e1b72f64e7" "${devcontainer_dockerfile}"
}

@test "Devcontainer Dockerfile installs Antigravity CLI and symlink" {
  local devcontainer_dockerfile="${LAYER_DIR}/.devcontainer/Dockerfile"
  grep -q "antigravity-cli" "${devcontainer_dockerfile}"
  grep -q "/usr/local/bin/agy" "${devcontainer_dockerfile}"
}

@test "Devcontainer Dockerfile installs Antigravity SDK and sets PYTHONPATH" {
  local devcontainer_dockerfile="${LAYER_DIR}/.devcontainer/Dockerfile"
  grep -q "/opt/antigravity-sdk" "${devcontainer_dockerfile}"
  grep -q "PYTHONPATH" "${devcontainer_dockerfile}"
}

@test "Dockerfile copies .devcontainer to /opt/devcontainer/intellij" {
  local dockerfile="${LAYER_DIR}/Dockerfile"
  grep -q "COPY .devcontainer/ /opt/devcontainer/intellij/" "${dockerfile}"
}

@test "Devcontainer Dockerfile provisions user with sudo" {
  local devcontainer_dockerfile="${LAYER_DIR}/.devcontainer/Dockerfile"
  grep -q "useradd" "${devcontainer_dockerfile}"
  grep -q "NOPASSWD:ALL" "${devcontainer_dockerfile}"
}

@test "devcontainer.json specifies overrideCommand false to preserve entrypoint" {
  local devcontainer_json="${LAYER_DIR}/.devcontainer/devcontainer.json"
  if command -v jq >/dev/null 2>&1; then
    run jq -r '.overrideCommand' "${devcontainer_json}"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
  else
    grep -q '"overrideCommand": false' "${devcontainer_json}"
  fi
}
