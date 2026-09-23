# syntax=docker/dockerfile:1.4

# Copyright 2024-2026 Google LLC
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

ARG GCP_REGION=us-central1
ARG BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_OPTS="-y --no-install-recommends"
ARG CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"
ARG CF_VER=1.57.0
ARG ASFP_VERSION=canary
ARG INSTALL_ABFS_CLIENT=false
ARG AOSP_PKGS="\
  bison \
  build-essential \
  curl \
  flex \
  fontconfig \
  git-core \
  gnome-terminal \
  gnupg \
  lib32z1-dev \
  libc6-dev-i386 \
  libgl1-mesa-dev \
  libncurses6 \
  libx11-dev \
  libxml2-utils \
  repo \
  rsync \
  unzip \
  x11proto-core-dev \
  xsltproc \
  zip \
  zlib1g-dev"
ARG ABFS_PKGS="abfs-client git psmisc rsync unzip zip"
ARG ASFP_DEB_URL="https://dl.google.com/android/asfp/asfp-${ASFP_VERSION}-current-linux.deb"

###############################################################
# Stage: Cuttlefish Builder
###############################################################
FROM ${GCP_REGION}-docker.pkg.dev/cloud-workstations-images/predefined/code-oss AS cuttlefish-builder
ARG CURL_OPTS
ARG CF_VER

SHELL ["/bin/bash", "-c"]

RUN mkdir -p /out && \
    PACKAGES_URL="https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts/dists/android-cuttlefish/main/binary-amd64/Packages" && \
    BASE_DEB=$(curl ${CURL_OPTS} "${PACKAGES_URL}" | grep -Eo "pool/android-cuttlefish/cuttlefish-base_${CF_VER}_amd64_[^ ]*\.deb" | tail -n1) && \
    USER_DEB=$(curl ${CURL_OPTS} "${PACKAGES_URL}" | grep -Eo "pool/android-cuttlefish/cuttlefish-user_${CF_VER}_amd64_[^ ]*\.deb" | tail -n1) && \
    curl ${CURL_OPTS} "https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts/${BASE_DEB}" -o /out/cuttlefish-base_amd64.deb && \
    curl ${CURL_OPTS} "https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts/${USER_DEB}" -o /out/cuttlefish-user_amd64.deb

###############################################################
# Stage: Main System
###############################################################
FROM ${BASE_IMAGE}
ARG ASFP_VERSION
ARG INSTALL_ABFS_CLIENT
ARG DEBIAN_FRONTEND
ARG APT_OPTS
ARG CURL_OPTS
ARG AOSP_PKGS
ARG ABFS_PKGS
ARG ASFP_DEB_URL

ENV ASFP_VERSION=${ASFP_VERSION}
ENV INSTALL_ABFS_CLIENT=${INSTALL_ABFS_CLIENT}
ENV APT_OPTS=${APT_OPTS}
ENV CURL_OPTS=${CURL_OPTS}
ENV EXTRA_PKGS="${AOSP_PKGS}"
ENV EXTRA_DEB_URLS="${ASFP_DEB_URL}"
ENV WORKSTATION_DEFAULT_APP="asfp-canary"

# Copy cuttlefish builder artifacts so they can be installed by hooks
COPY --from=cuttlefish-builder /out /cuttlefish

# Merge assets into the container.
COPY assets/ /

# Perform centralized workstation configuration (hooks, packages, and integration).
RUN if [ "${INSTALL_ABFS_CLIENT}" = "true" ]; then \
      export EXTRA_PKGS="${EXTRA_PKGS} ${ABFS_PKGS}"; \
    fi && \
    /google/scripts/build/configure_workstation.sh
