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
setup() { setup_env; }

@test "Android Studio for Platform is installed" {
  run run_ssh "ls -l /opt/android-studio-for-platform-canary/bin/studio"
  [ "$status" -eq 0 ]
}

@test "AOSP tooling: repo is available" {
  run run_ssh "repo --version"
  [ "$status" -eq 0 ]
}

@test "AOSP tooling: build-essential is installed" {
  run run_ssh "dpkg -l build-essential"
  [ "$status" -eq 0 ]
}

@test "Cuttlefish: base packages are installed" {
  run run_ssh "dpkg -l cuttlefish-base cuttlefish-user"
  [ "$status" -eq 0 ]
}

@test "Cuttlefish: user is in kvm group" {
  run run_ssh "source /google/scripts/common.sh && groups \$WORKSTATION_USER | grep -q 'kvm'"
  [ "$status" -eq 0 ]
}

@test "Cuttlefish: user is in cvdnetwork group" {
  run run_ssh "source /google/scripts/common.sh && groups \$WORKSTATION_USER | grep -q 'cvdnetwork'"
  [ "$status" -eq 0 ]
}

@test "ASFP VM options are patched for memory" {
  run run_ssh "grep -q 'Xmx' /opt/android-studio-for-platform-canary/bin/studio64.vmoptions"
  [ "$status" -eq 0 ]
}

@test "ASFP is registered for autostart" {
  assert_app_autostarted "asfp-canary"
}

@test "ASFP is pinned to the dock" {
  assert_app_pinned "asfp-canary"
}

@test "AOSP helper scripts are available in /google/scripts" {
  scripts=("build_aosp.sh" "build_vcar.sh" "start_vcar_cvd.sh" "stop_vcar_cvd.sh")
  for script in "${scripts[@]}"; do
    run run_ssh "ls -l /google/scripts/${script}"
    [ "$status" -eq 0 ]
  done
}
