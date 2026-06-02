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

@test "xfreerdp3 can be installed for local testing" {
  run run_ssh "sudo apt-get update -yqq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq freerdp3-x11 xvfb > /dev/null"
  [ "$status" -eq 0 ]
}

@test "xfreerdp3 successfully authenticates with the RDP daemon" {
  run run_ssh "source /google/scripts/common.sh && source \$EPHEMERAL_ENV_PATH && \
    export RDP_ARGS=\"/v:\$RDP_HOST:\$RDP_PORT
/u:\$WORKSTATION_USER
/p:\$EPHEMERAL_PASS
/cert:ignore\" && \
    timeout 10s xvfb-run xfreerdp3 /args-from:env:RDP_ARGS 2>&1 | grep -q 'gdi_init_ex'"
  [ "$status" -eq 0 ]
}
