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

setup() {
  # Load common logic to get REPO_ROOT
  # We assume bats is run from somewhere where we can find repo root
  find_repo_root() {
    local dir="${1}"
    while [[ "${dir}" != "/" ]]; do
      if [[ -f "${dir}/skills/common.sh" ]]; then
        echo "${dir}"
        return 0
      fi
      dir="$(dirname "${dir}")"
    done
    return 1
  }
  REPO_ROOT="$(find_repo_root "$(pwd)")"
  if [[ -z "${REPO_ROOT}" ]]; then
    echo "Error: Could not find REPO_ROOT" >&2
    exit 1
  fi
}

# Helper to extract YAML value from frontmatter
get_yaml_value() {
  local file="${1}"
  local key="${2}"
  local parent="${3:-}"
  local val
  if [[ -n "${parent}" ]]; then
    # Extracts value from a nested mapping under 'parent:'
    val=$(sed -n "/^${parent}:/,/^[^ ]/p" "${file}" | grep "^  ${key}:" | head -n 1 | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  else
    # Extracts the top-level value after 'key:', trims whitespace
    val=$(grep "^${key}:" "${file}" | head -n 1 | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi
  # Strip surrounding quotes if present
  echo "${val}" | sed 's/^"//;s/"$//;s/^\x27//;s/\x27$//'
}

# Helper to extract list items from YAML metadata mapping
get_yaml_metadata_list() {
  local file="${1}"
  local key="${2}"
  # This is a simplified parser for:
  # metadata:
  #   key:
  #     - item1
  #     - item2
  sed -n "/^metadata:/,/^[^ ]/p" "${file}" | sed -n "/^  ${key}:/,/^  [^ ]/p" | grep "^    - " | sed 's/^    - //'
}

# Helper to extract space-separated tools
get_allowed_tools() {
  local file="${1}"
  get_yaml_value "${file}" "allowed-tools"
}

validate_skill() {
  local skill_path="${1}"
  local skill_file="${REPO_ROOT}/${skill_path}/SKILL.md"

  [ -f "${skill_file}" ]

  # Strict Structural Requirement: YAML must start at Line 1
  [ "$(head -n 1 "${skill_file}")" == "---" ]

  # Mandatory fields
  local name
  name=$(get_yaml_value "${skill_file}" "name")
  [ -n "${name}" ]

  local description
  description=$(get_yaml_value "${skill_file}" "description")
  [ -n "${description}" ]

  local license
  license=$(get_yaml_value "${skill_file}" "license")
  [ "${license}" == "Apache-2.0" ]

  # Metadata extensions
  local author
  author=$(get_yaml_value "${skill_file}" "author" "metadata")

  local expected_author
  expected_author="$(git config user.name) <$(git config user.email)>"
  [ "${author}" == "${expected_author}" ]

  # Validate Tools (space-separated)
  local tools
  tools=$(get_allowed_tools "${skill_file}")
  if [[ -n "${tools}" ]]; then
    local tool
    for tool in ${tools}; do
      [ -e "${REPO_ROOT}/${tool}" ]
    done
  fi

  # Validate Resources (list under metadata)
  local resource
  for resource in $(get_yaml_metadata_list "${skill_file}" "resources"); do
    [ -e "${REPO_ROOT}/${resource}" ]
  done
}

@test "validate skill: persona-agent-manager" {
  validate_skill "skills/persona-agent-manager"
}

@test "validate skill: persona-legal" {
  validate_skill "skills/persona-legal"
}

@test "validate skill: persona-oss" {
  validate_skill "skills/persona-oss"
}

@test "validate skill: persona-privacy" {
  validate_skill "skills/persona-privacy"
}

@test "validate skill: persona-security" {
  validate_skill "skills/persona-security"
}

@test "validate skill: persona-sre" {
  validate_skill "skills/persona-sre"
}

@test "validate skill: persona-swe" {
  validate_skill "skills/persona-swe"
}

@test "validate skill: persona-ux" {
  validate_skill "skills/persona-ux"
}

@test "validate skill: validate-image-updates" {
  validate_skill "skills/validate-image-updates"
}

@test "validate skill: update-preflight" {
  validate_skill "apps/workstations/preflight/skills/update-preflight"
}
