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

set -euo pipefail

# Provides generic installation and asset-fetching utilities for layers building on top of base.

# Source common for retries and logging if available
if [[ -f /google/scripts/common.sh ]]; then
  # shellcheck source=apps/workstations/common/assets/google/scripts/common.sh
  source /google/scripts/common.sh
fi

download_and_validate() {
  local url="$1"
  local sha256="$2"
  local output_file="$3"

  echo "Downloading from ${url}..."
  curl ${CURL_OPTS:--fsSL --retry 3} "${url}" -o "${output_file}"
  
  if [[ "${sha256}" != "NOCHECK" ]]; then
    echo "${sha256}  ${output_file}" | sha256sum -c -
  else
    echo "NOCHECK passed. Skipping sha256 validation."
  fi
}

install_file_from_tarball() {
  local url="$1"
  local sha256="$2"
  local dest_dir="$3"
  local file_pattern="$4"
  
  local tmp_dir="/tmp/selective_unpacking_${RANDOM}"
  local filename
  filename=$(basename "$url")
  
  mkdir -p "$tmp_dir" "$dest_dir"
  download_and_validate "$url" "$sha256" "${tmp_dir}/${filename}"
  
  echo "--> Extracting ${filename}"
  tar -xzf "${tmp_dir}/${filename}" -C "$tmp_dir"
  
  echo "--> Moving files matching '${file_pattern}' to ${dest_dir}"
  find "$tmp_dir" -type f -name "${file_pattern}" -exec mv -f {} "$dest_dir/" \;
  
  rm -rf "$tmp_dir"
}

extract_tarball() {
  local tarball_name="$1"
  local destination_dir="$2"
  shift 2
  local additional_tar_args=("$@")

  mkdir -p "${destination_dir}"
  tar -xzf "${tarball_name}" -C "${destination_dir}" "${additional_tar_args[@]}"
  rm -f "${tarball_name}"
}

install_binary_from_tarball() {
    local url="$1"
    local sha256="$2"
    local tarball_name="$3"
    local file_to_extract="$4"
    local install_dir="$5"
    local install_name="$6"
    shift 6
    local aliases=("$@")

    download_and_validate "${url}" "${sha256}" "${tarball_name}"
    tar -xzf "${tarball_name}" "${file_to_extract}"
    mkdir -p "${install_dir}"
    mv "${file_to_extract}" "${install_dir}/${install_name}"

    for alias_name in "${aliases[@]}"; do
        ln -sf "${install_name}" "${install_dir}/${alias_name}"
    done

    rm -f "${tarball_name}"
}

fetch_crane() {
  local crane_version="${CRANE_VERSION:-v0.21.5}"
  local crane_sha256="${CRANE_SHA256:-9f823ae5ee25803161110f957b5fd4538f714d40cdf25dacb4914fefafd246bf}"
  local crane_url="https://github.com/google/go-containerregistry/releases/download/${crane_version}/go-containerregistry_Linux_x86_64.tar.gz"
  
  echo "Installing crane from ${crane_url}..."
  install_binary_from_tarball "${crane_url}" "${crane_sha256}" "crane.tar.gz" "crane" "/usr/local/bin" "crane"
}

fetch_image() {
  local image_id="$1"
  local output_tar="$2"
  local retries="${RETRIES:-3}"
  local retry_wait="${RETRY_WAIT:-5}"
  local crane_timeout="${CRANE_TIMEOUT:-300}"

  echo "Pulling ${image_id} to ${output_tar}..."
  local i=1
  local pull_success=false
  
  while [[ "$i" -le "${retries}" ]]; do
    if timeout "${crane_timeout}" crane pull "${image_id}" "${output_tar}"; then
      pull_success=true
      break
    fi
    
    echo "Retry $i/${retries} for ${image_id}..."
    i=$((i + 1))
    sleep "${retry_wait}"
  done

  if [ "$pull_success" = false ]; then
    echo "ERROR: Failed to pull ${image_id} after ${retries} attempts."
    exit 1
  fi
}

resolve_url() {
  local path="$1"
  if [[ "${path}" == gs://* ]] || [[ "${path}" == http://* ]] || [[ "${path}" == https://* ]]; then
    echo "${path}"
  else
    # Fallback to appending internal software bucket if purely relative
    echo "${GCS_SOFTWARE_BUCKET:-gs://ws-image-3rd-software}/${path}"
  fi
}

install_archive() {
  local raw_path="$1"
  local dest_dir="$2"
  
  if [[ "$raw_path" != *\** ]] && [[ "$raw_path" != *.tar* ]] && [[ "$raw_path" != *.zip ]] && [[ "$raw_path" != *.deb ]]; then
    raw_path="${raw_path}/*"
  fi

  local source_url
  source_url=$(resolve_url "$raw_path")
  local tmp_dir="/tmp/archive_unpacking_${RANDOM}"

  mkdir -p "$tmp_dir"
  mkdir -p "$dest_dir"

  echo "--> Fetching $source_url"
  if [[ "$source_url" == gs://* ]]; then
    gsutil cp -r "$source_url" "$tmp_dir/"
  else
    # HTTP/HTTPS fallback uses curl. Warning: Glob downloading via curl is unreliable. Use explicit urls.
    curl ${CURL_OPTS:--fsSL --retry 3} -O "$source_url"
    mv "$(basename "$source_url")" "$tmp_dir/"
  fi

  echo "--> Extracting into $dest_dir"
  for file in "$tmp_dir"/*; do
      [[ -e "$file" ]] || continue
      case "$file" in
          *.tar.gz|*.tgz) tar xfz "$file" -C "$dest_dir" ;;
          *.tar.bz2)      tar xfj "$file" -C "$dest_dir" ;;
          *.tar.xz)       tar xfJ "$file" -C "$dest_dir" ;;
          *.zip)          unzip -q "$file" -d "$dest_dir" ;;
          *.deb)          dpkg -i "$file" ;;
          *)              echo "Moved unarchived artifact: $file"; mv -f "$file" "$dest_dir/" ;;
      esac
  done

  echo "--> Cleaning up $tmp_dir"
  rm -rf "$tmp_dir"
}

install_debs() {
  for raw_path in "$@"; do
    local tool_path="$raw_path"
    if [[ "$tool_path" != *\** ]] && [[ "$tool_path" != *.deb ]]; then
      tool_path="${tool_path}/*"
    fi

    local source_url
    source_url=$(resolve_url "$tool_path")
    local tmp_dir="/tmp/deb_unpacking_${RANDOM}"
    
    mkdir -p "$tmp_dir"
    echo "--> Fetching DEB bundle from $source_url"
    if [[ "$source_url" == gs://* ]]; then
      gsutil cp -r "$source_url" "$tmp_dir/"
    else
      curl ${CURL_OPTS:--fsSL --retry 3} -O "$source_url"
      mv "$(basename "$source_url")" "$tmp_dir/"
    fi
    
    echo "--> Installing DEB bundle for $raw_path"
    dpkg -i "$tmp_dir"/*.deb || true
    
    echo "--> Cleaning up segment"
    rm -rf "$tmp_dir"
  done
}

configure_apt() {
  local region="${GCP_REGION:-us-central1}"
  echo "Configuring APT repositories for region: ${region}..."

  # Replace default region in all .list files
  sed -i "s/us-central1/${region}/g" /etc/apt/sources.list.d/*.list 2>/dev/null || true
}

install_core_packages() {
  local CORE_PKGS="bzip2 ca-certificates curl dbus-user-session tar wget xz-utils"
  log "Installing core packages: ${CORE_PKGS}..."
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends ${CORE_PKGS}
}

install_packages() {
  if [[ -n "${EXTRA_PKGS:-}" ]]; then
    log "Installing extra packages: ${EXTRA_PKGS}..."
    # shellcheck disable=SC2086
    apt-get install -y --no-install-recommends ${EXTRA_PKGS}
  fi
}

install_extra_debs() {
  if [[ -n "${EXTRA_DEB_URLS:-}" ]]; then
    echo "Installing extra .deb packages from URLs..."
    # shellcheck disable=SC2086
    install_debs ${EXTRA_DEB_URLS}
  fi
}

purge_and_hold_packages() {
  if [[ -n "${PURGE_PKGS:-}" ]]; then
    log "Purging packages: ${PURGE_PKGS}..."
    # shellcheck disable=SC2086
    apt-get purge -y ${PURGE_PKGS} 2>/dev/null || true
  fi

  if [[ -n "${HOLD_PKGS:-}" ]]; then
    log "Holding packages: ${HOLD_PKGS}..."
    # shellcheck disable=SC2086
    apt-mark hold ${HOLD_PKGS} 2>/dev/null || true
  fi

  # Clean default webserver files if present
  rm -f /var/www/html/index.html /var/www/html/index.nginx-debian.html
}
