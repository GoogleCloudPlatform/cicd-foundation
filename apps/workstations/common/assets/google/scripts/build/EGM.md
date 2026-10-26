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

# Common Workstation Build Scripts (`build`)

## Overview

Contains `configure_workstation.sh` and `install_functions.sh`, which provide
centralized build-time orchestration, asset permission normalization, APT
repository/package lifecycle management, hook execution, systemd service
enablement, and remote artifact/container fetching for Cloud Workstation
container layers.

## Interface

- `configure_workstation.sh`: `main [--hooks-dir <dir>] [--post-hooks-dir
  <dir>] [--skip-apt-update|--skip-apt] [--skip-cleanup] [<hooks_subdir>]`,
  `prepare_assets <hooks_dir> <post_hooks_dir>`, `apply_permissions <mode>
  <paths...>`, `readonly SCRIPTS_PATHS="/google/scripts
  /etc/workstation-startup.d /usr/local/bin"`, and `readonly
  CONFIG_PATHS="/etc/apt/sources.list.d /etc/apt/keyrings /etc/systemd/user
  /etc/xdg/autostart /google/templates"`.
- `install_functions.sh`: `download_and_validate <url> <sha256|NOCHECK>
<output_file>`, `install_file_from_tarball <url> <sha256> <dest_dir>
<file_pattern>`, `extract_tarball <tarball_name> <destination_dir>
[additional_tar_args...]`, `install_binary_from_tarball <url> <sha256>
<tarball_name> <file_to_extract> <install_dir> <install_name> [aliases...]`,
  `fetch_crane` (uses `CRANE_VERSION`, `CRANE_SHA256`), `fetch_image
<image_id> <output_tar>` (uses `RETRIES`, `RETRY_WAIT`, `CRANE_TIMEOUT`),
  `resolve_url <path>` (uses `GCS_SOFTWARE_BUCKET`), `install_archive
<raw_path> <dest_dir>` (uses `CURL_OPTS`), `install_debs <raw_paths...>`
  (uses `CURL_OPTS`), `configure_apt` (uses `GCP_REGION`),
  `install_core_packages`, `install_packages` (uses `EXTRA_PKGS`),
  `install_extra_debs` (uses `EXTRA_DEB_URLS`), and `purge_and_hold_packages`
  (uses `PURGE_PKGS`, `HOLD_PKGS`).

## Invariants

- Both scripts enforce strict shell execution mode (`set -euo pipefail`).
- `prepare_assets` guarantees directories in `SCRIPTS_PATHS`, `CONFIG_PATHS`,
  `hooks_dir`, and `post_hooks_dir` (plus `/etc`, `/google`,
  `/google/scripts`, `/usr/share/applications`) have mode `755`, script files
  have `+x`, and config files have mode `644`.
- Registration hooks in `hooks_dir` (default `/build-hooks.d/`) always execute
  before the secondary `apt-get update` and installation of
  `EXTRA_PKGS`/`EXTRA_DEB_URLS`, while `post_hooks_dir` (default
  `/post-install-hooks.d/`) always executes after package installation.
- When APT is not skipped and any `/etc/apt/sources.list.d/*.list` file
  references an `ar+` repository without `apt-transport-artifact-registry`
  installed, `apt-transport-artifact-registry` is installed and `apt-get
update` is re-run before `install_packages`.
- `download_and_validate` enforces SHA-256 verification via `sha256sum -c -`
  unless the checksum parameter is literally `NOCHECK`.
- `fetch_image` retries `crane pull` up to `RETRIES` (default `3`) times with
  timeout `CRANE_TIMEOUT` (default `300`s) and exits with status `1` if all
  attempts fail.
- `resolve_url` preserves `gs://`, `http://`, and `https://` URLs and prefixes
  relative paths with `${GCS_SOFTWARE_BUCKET:-gs://ws-image-3rd-software}/`.
- SSH readiness is guaranteed by removing `/etc/ssh/sshd_not_to_be_run`,
  generating host keys (`ssh-keygen -A`), and symlinking `ssh.service` and
  `ssh.socket` into systemd `.wants` directories.
- All `/etc/systemd/system/*.service` unit files containing an `[Install]`
  section are symlinked into `/etc/systemd/system/multi-user.target.wants/`.

## Side Effects

- Mutates directory and file permissions (`chmod`) across system, asset, and
  hook paths.
- Rewrites `us-central1` to `${GCP_REGION:-us-central1}` in-place across
  `/etc/apt/sources.list.d/*.list` via `sed -i`.
- Executes `apt-get update`, `apt-get install`, `apt-get purge`, `apt-mark
hold`, `apt-get autoremove -y`, `apt-get clean`, and `dpkg -i`, modifying
  system packages and deleting `/var/lib/apt/lists/*`.
- Deletes `/var/www/html/index.html`, `/var/www/html/index.nginx-debian.html`,
  `/etc/ssh/sshd_not_to_be_run`, and (unless `--skip-cleanup` is passed)
  `hooks_dir` and `post_hooks_dir`.
- Executes arbitrary `.sh` scripts in `hooks_dir` and `post_hooks_dir` (via
  `run_hooks` from `/google/scripts/common.sh`) and conditionally sources and
  runs `desktop_apply_integration` from
  `/google/scripts/build/desktop_integration.sh`.
- Performs network I/O via `curl`, `gsutil cp -r`, and `crane pull`, creating
  and deleting temporary directories under `/tmp/` (`selective_unpacking_*`,
  `archive_unpacking_*`, `deb_unpacking_*`) and installing binaries/symlinks
  into destination directories such as `/usr/local/bin`.
- Generates SSH host keys (`ssh-keygen -A`), updates dconf databases (`dconf
update`), creates symlinks in `/etc/systemd/system/multi-user.target.wants`
  and `/etc/systemd/system/sockets.target.wants`, and emits `BUILD_START` and
  `BUILD_COMPLETE` events to stdout.
