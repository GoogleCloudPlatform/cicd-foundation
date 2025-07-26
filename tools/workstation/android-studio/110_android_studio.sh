# !/bin/bash

# Copyright 2022-2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "Starting xpra server, session will terminate when Android Studio is Closed."

function start_android_studio {
  runuser user -c -l "xpra start --min-port=80 --bind-tcp=0.0.0.0:80 --html=on --exit-with-children=yes --systemd-run=no --daemon=no --start-child-after-connect=/opt/google/android-studio/bin/studio.sh"
}

function kill_container {
  echo "Android Studio exited, terminating container."
  ps x | awk {'{print $1}'} | awk 'NR > 1' | xargs kill
}

(start_android_studio || kill_container)&
