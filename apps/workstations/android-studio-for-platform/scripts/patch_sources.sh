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

# This script replaces unreliable git.kernel.org URLs with GitHub mirrors
# to ensure build stability in environments with connectivity issues to kernel.org.

set -euo pipefail

TARGET_DIR="${1:-/android-cuttlefish}"

echo "Patching source URLs in ${TARGET_DIR}..."

# Define replacements: "Pattern" "Replacement"
declare -A REPLACEMENTS=(
    ["https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools[a-zA-Z0-9./-]*"]="https://github.com/jaegeuk/f2fs-tools.git"
    # Add more here if needed
)

for pattern in "${!REPLACEMENTS[@]}"; do
    replacement="${REPLACEMENTS[$pattern]}"
    echo "  -> Replacing ${pattern} with ${replacement}"
    find "${TARGET_DIR}" -type f -exec sed -i "s|${pattern}|${replacement}|g" {} +
done

echo "Patching complete."
