<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# ASfP Google Scripts (`scripts`)

## Overview

Helper scripts in `/google/scripts` for synchronizing and compiling AOSP
(Android Open Source Project) and Android Automotive OS (`AAOS` / `VCAR`)
repositories (`build_aosp.sh`, `build_vcar.sh`), managing the lifecycle of
Cuttlefish Virtual Device instances (`start_vcar_cvd.sh`, `stop_vcar_cvd.sh`),
and sanitizing user credentials before taking disk snapshots
(`cleanup_for_snapshot.sh`).

## Interface

- `build_aosp.sh [-o|--output_dir <dir>] [-u|--repo_url <url>] [-b|--branch
<branch>] [-t|--build_target <target>] [-c|--thread_count <threads>]
[-h|--help]`: Functions `main`, `_sync_and_build_repo`, `_print_usage`, and
  `_cli_errors`.
- `build_vcar.sh`: Downloads and compiles the `android15-automotiveos-dev`
  branch (`aosp_cf_x86_64_auto-ap4a-userdebug`) and Compatibility Test Suite
  (`CTS`) into `${HOME}/aaos/vcar`.
- `start_vcar_cvd.sh`: Launches the AAOS Cuttlefish Virtual Device with WebRTC
  enabled (`launch_cvd --start_webrtc=true &`).
- `stop_vcar_cvd.sh`: Stops the running AAOS Cuttlefish Virtual Device via
  `stop_cvd`.
- `cleanup_for_snapshot.sh`: Removes user-specific credentials and browser
  state (`~/.gitcookies`, `~/gitconfig`, `~/.config/google-chrome`) prior to
  disk snapshotting.

## Invariants

- `build_aosp.sh` drops root privileges by re-executing itself as `user` via
  `exec runuser user` when `EUID` is `0`.
- `build_aosp.sh` defaults to `OUTPUT_DIR=${HOME}/aosp`,
  `REPO_URL=https://android.googlesource.com/platform/manifest`,
  `BRANCH=main`, `BUILD_TARGET=aosp_cf_x86_64_phone-trunk_staging-userdebug`,
  and `THREAD_COUNT=$(( $(nproc) * 49 / 100 ))`.
- `build_vcar.sh` targets `CODEBASE_DIR=${HOME}/aaos/vcar`, branch
  `android15-automotiveos-dev`, lunch target
  `aosp_cf_x86_64_auto-ap4a-userdebug`, and CTS product `aosp_cf_x86_64_auto`
  (`TARGET_RELEASE=ap4a`, `TARGET_BUILD_VARIANT=userdebug`).
- `start_vcar_cvd.sh` and `stop_vcar_cvd.sh` require an existing checkout at
  `${HOME}/aaos/vcar` containing `build/envsetup.sh` and target lunch
  configuration `aosp_cf_x86_64_auto-ap4a-userdebug`.

## Side Effects

- `build_aosp.sh` creates the target output directory, changes ownership of
  `/usr/bin/repo` to `user:user` via `sudo chown`, sets global Git
  `user.email` (`aosp-builder`) and `user.name` (`AOSP Builder`) if
  unconfigured, initializes and syncs the AOSP repo (`--partial-clone`),
  compiles the target via `lunch` and `m`, and emits structured events
  (`AOSP_SYNC_START`, `AOSP_BUILD_START`, `AOSP_BUILD_COMPLETE`) via
  `/google/scripts/common.sh`.
- `build_vcar.sh` invokes `/google/scripts/build_aosp.sh`, runs `m cts`, and
  emits structured events (`VCAR_BUILD_START`, `CTS_BUILD_START`,
  `VCAR_BUILD_COMPLETE`).
- `start_vcar_cvd.sh` and `stop_vcar_cvd.sh` start (`launch_cvd
--start_webrtc=true &`) and stop (`stop_cvd`) background Cuttlefish emulator
  processes.
- `cleanup_for_snapshot.sh` deletes `~/.gitcookies`, `~/gitconfig`, and
  `~/.config/google-chrome`.
