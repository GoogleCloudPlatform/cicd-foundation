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

@test "Chrome wrapper script contains suppression and stability flags" {
  local wrapper="${GNOME_LAYER_DIR}/assets/usr/local/bin/google-chrome-stable"
  grep -q -- "--no-first-run" "${wrapper}"
  grep -q -- "--no-default-browser-check" "${wrapper}"
  grep -q -- "--ozone-platform=wayland" "${wrapper}"
  grep -q -- "--in-process-gpu" "${wrapper}"
}

@test "Chrome managed policy file exists and is valid JSON" {
  local policy_file="${ASSETS_DIR}/etc/opt/chrome/policies/managed/default_policy.json"
  [ -f "$policy_file" ]

  # Verify specific policy settings
  grep -q '"DefaultBrowserSettingEnabled": false' "$policy_file"
  grep -q '"MetricsReportingEnabled": false' "$policy_file"
}
