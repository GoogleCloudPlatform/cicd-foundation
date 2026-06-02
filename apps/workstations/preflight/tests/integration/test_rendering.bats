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

@test "Nginx configuration template was fully rendered" {
  # We check if the Guacamole backend port was rendered (8080 for Tomcat/Guacamole)
  run run_ssh "sudo test -f /etc/nginx/sites-available/default && sudo grep -q 'http://127.0.0.1:8080' /etc/nginx/sites-available/default"
  [ "$status" -eq 0 ]
}

@test "Ephemeral password file exists" {
  run run_ssh "source /google/scripts/common.sh && sudo test -f \$EPHEMERAL_ENV_PATH"
  [ "$status" -eq 0 ]
}

@test "Guacamole user mapping file exists" {
  run run_ssh "sudo test -f /etc/guacamole/user-mapping.xml"
  [ "$status" -eq 0 ]
}

@test "Passwords match between ephemeral.env and Guacamole mapping" {
  run run_ssh "source /google/scripts/common.sh &&
    ENV_PASS=\$(sudo grep '^EPHEMERAL_PASS=' \$EPHEMERAL_ENV_PATH | cut -d'\"' -f2)
    XML_PASS=\$(sudo grep '<param name=\"password\">' /etc/guacamole/user-mapping.xml | sed -e 's/.*<param name=\"password\">//' -e 's/<\\/param>.*//')
    [ -n \"\$ENV_PASS\" ] && [ -n \"\$XML_PASS\" ] && [ \"\$ENV_PASS\" == \"\$XML_PASS\" ]
  "
  [ "$status" -eq 0 ]
}
