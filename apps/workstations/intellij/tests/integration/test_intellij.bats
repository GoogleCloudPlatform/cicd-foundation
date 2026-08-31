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

@test "SSH daemon is active on port 22" {
  run run_ssh "sudo ss -tulpn | grep -q ':22 '"
  [ "$status" -eq 0 ]
}

@test "Port 80 Nginx is listening" {
  run run_ssh "sudo ss -tulpn | grep -q ':80 '"
  [ "$status" -eq 0 ]
}

@test "IntelliJ IDEA installation exists in /opt/ideaIU" {
  run run_ssh "test -d /opt/ideaIU && test -x /opt/ideaIU/bin/remote-dev-server"
  [ "$status" -eq 0 ]
}

@test "Preflight startup page is served" {
  run run_ssh "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/ | grep -qE '^(200|302)$'"
  [ "$status" -eq 0 ]
}
