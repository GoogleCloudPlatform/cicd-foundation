#!/bin/bash

# Copyright 2025-2026 Google LLC
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

#
# This script downloads the Android Automotive OS 15 branch and builds
# the Cuttlefish Virtual Device and the Compatibility Test Suite (CTS).

# References
# Manifest: https://android.googlesource.com/platform/manifest/+/refs/heads/android15-automotiveos-dev
# Changes: https://android-review.googlesource.com/q/branch:android15-automotiveos-dev

# Source common utilities
# shellcheck source=/dev/null
source /google/scripts/common.sh

CODEBASE_DIR="${HOME}/aaos/vcar"

log_event VCAR_BUILD_START "Starting VCAR build"
log "Syncing & building aosp_cf_x86_64_auto-ap4a-userdebug"
/google/scripts/build_aosp.sh -o "${CODEBASE_DIR}" \
  -b android15-automotiveos-dev \
  -t aosp_cf_x86_64_auto-ap4a-userdebug

log_event CTS_BUILD_START "Starting CTS build"
pushd "${CODEBASE_DIR}" > /dev/null 2>&1 || exit
# shellcheck source=/dev/null
source build/envsetup.sh
m cts TARGET_PRODUCT=aosp_cf_x86_64_auto \
    TARGET_RELEASE=ap4a \
    TARGET_BUILD_VARIANT=userdebug
popd > /dev/null 2>&1 || exit
log_event VCAR_BUILD_COMPLETE "VCAR build finished"
