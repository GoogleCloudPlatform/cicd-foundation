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

file="slides/00_intro.md"
first_line=$(sed -e '/^<!--/,/-->/d' "${file}" | sed '/^[[:space:]]*$/d' | head -n 1)
if [[ "${first_line}" == "# "* ]]; then
  header=$(echo "${first_line}" | sed 's/^#\+ //')
  body=$(awk '!found && /^# / {found=1; next} {print}' "${file}")
else
  header=""
  body=$(cat "${file}")
fi
echo "HEADER: $header"
echo "BODY:"
echo "$body" | head -n 5
