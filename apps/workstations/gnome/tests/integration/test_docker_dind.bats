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

@test "Docker service is active and socket exists" {
  run run_ssh "sudo systemctl is-active docker.service --quiet"
  [ "$status" -eq 0 ]
  run run_ssh "sudo test -S /run/docker.sock"
  [ "$status" -eq 0 ]
}

@test "Docker-in-Docker container execution was successful" {
  run run_ssh "sudo docker run --rm alpine:latest echo 'DinD works'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "DinD works" ]]
}
