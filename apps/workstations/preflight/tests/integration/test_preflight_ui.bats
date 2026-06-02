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

setup() {
  setup_env
}

@test "Nginx is serving and redirecting requests successfully" {
  run run_ssh "curl -s -o /dev/null -w '%{http_code}' http://localhost/ | grep -q '302'"
  [ "$status" -eq 0 ]
}

@test "External traffic was successfully allowed by permit-traffic service" {
  run run_ssh "sudo systemctl is-active permit-traffic.service --quiet"
  [ "$status" -eq 0 ]
}

@test "Hard Silence: nftables management table is removed" {
  # After permit-traffic.service finishes, the management table must be deleted
  run run_ssh "sudo nft list tables | grep -q 'workstation_mgmt'"
  [ "$status" -eq 1 ]
}
