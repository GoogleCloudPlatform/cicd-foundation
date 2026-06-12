#!/bin/bash

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

source ./bin/md2tty.sh
load_locales
output=$(show_shortcuts "1" "1" <<< "q")
clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/→/./g; s/←/./g')
echo "=== CLEAN OUTPUT ==="
echo "$clean_output"
echo "=== EXTRACTED ROWS ==="
home_row=$(echo "$clean_output" | grep "Home" | head -n 1)
header_row=$(echo "$clean_output" | grep "Key" | head -n 1)
help_row=$(echo "$clean_output" | grep "h, ?" | head -n 1)
echo "HOME: $home_row"
echo "HEADER: $header_row"
echo "HELP: $help_row"
echo "WC HOME: $(echo "$home_row" | tr -cd '│' | wc -c)"
