# syntax=docker/dockerfile:1.4

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

ARG GCP_REGION=us-central1
ARG CWS_BASE_IMAGE_TAG=latest
ARG ALPINE_VERSION=3.19
ARG BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_TIGERVNC=false
ARG INSTALL_CHROME_REMOTE_DESKTOP=false
ARG GUACAMOLE_VERSION=1.6.0
ARG CONTAINER_REGISTRY="mirror.gcr.io"
ARG DEFAULT_ENABLE_AUDIO_INPUT=false
ARG APP_STARTUP_DELAY=5
ARG DEFAULT_CLIENT_PROTOCOL="RDP"
ARG SUPPORTED_PROTOCOLS="RDP,SSH"

ARG CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"
ARG DPKG_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
ARG APT_OPTS="-y --no-install-recommends"
ARG BASE_PKGS="apt-transport-artifact-registry curl dbus-user-session gettext-base gnome-keyring gnupg nginx openssh-server systemd unzip winpr3-utils nodejs zip"
ARG CHROME_PKGS="google-chrome-stable"
ARG TIGERVNC_PKGS="tigervnc-common tigervnc-scraping-server tigervnc-standalone-server tigervnc-xorg-extension"
ARG CRD_PKGS="chrome-remote-desktop"
ARG PURGE_PKGS="apache2* php*"
ARG HOLD_PKGS="apache2 apache2-bin apache2-data apache2-utils php*"

ARG GUACAMOLE_EXTENSIONS=""
ARG GUACAMOLE_IMAGES="guacd guacamole"
ARG RETRIES=3
ARG RETRY_WAIT=5
ARG CRANE_TIMEOUT=300
ARG CRANE_VERSION=v0.21.5
ARG CRANE_SHA256=9f823ae5ee25803161110f957b5fd4538f714d40cdf25dacb4914fefafd246bf
ARG CRANE_URL="https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz"
ARG FETCHER_PKGS="bash ca-certificates curl tar"
ARG GUACAMOLE_BASE_URL="https://archive.apache.org/dist/guacamole/${GUACAMOLE_VERSION}/binary"

###############################################################
# Stage: asset-prep
###############################################################
FROM alpine:${ALPINE_VERSION} AS asset-prep
COPY assets/ /assets/
RUN find /assets/etc -type d -exec chmod 755 {} + && \
    find /assets/etc -type f -exec chmod 644 {} + && \
    find /assets/usr/local/bin -type d -exec chmod 755 {} + && \
    find /assets/usr/local/bin -type f -exec chmod 755 {} +

###############################################################
# Stage: base-provider 
###############################################################
FROM ${BASE_IMAGE} AS base-provider
ARG BASE_IMAGE

###############################################################
# Stage: fetcher
###############################################################
FROM alpine:${ALPINE_VERSION} AS fetcher
ARG ALPINE_VERSION
ARG CURL_OPTS
ARG GUACAMOLE_VERSION
ARG GUACAMOLE_EXTENSIONS
ARG GUACAMOLE_IMAGES
ARG RETRIES
ARG RETRY_WAIT
ARG CONTAINER_REGISTRY
ARG CRANE_TIMEOUT
ARG CRANE_VERSION
ARG CRANE_SHA256
ARG CRANE_URL
ARG FETCHER_PKGS
ARG GUACAMOLE_BASE_URL

ENV CURL_OPTS=${CURL_OPTS}
ENV GUACAMOLE_VERSION=${GUACAMOLE_VERSION}
ENV GUACAMOLE_EXTENSIONS=${GUACAMOLE_EXTENSIONS}
ENV GUACAMOLE_IMAGES=${GUACAMOLE_IMAGES}
ENV RETRIES=${RETRIES}
ENV RETRY_WAIT=${RETRY_WAIT}
ENV CONTAINER_REGISTRY="${CONTAINER_REGISTRY}"
ENV CRANE_TIMEOUT=${CRANE_TIMEOUT}
ENV CRANE_URL=${CRANE_URL}
ENV CRANE_SHA256=${CRANE_SHA256}
ENV GUACAMOLE_BASE_URL=${GUACAMOLE_BASE_URL}

WORKDIR /downloads
RUN apk add --no-cache ${FETCHER_PKGS}
# Ensure the base-provider utility library is natively injected into Alpine fetcher
COPY --from=base-provider /export/google/scripts/common.sh /google/scripts/common.sh
COPY --from=base-provider /export/google/scripts/build/install_functions.sh /google/scripts/build/install_functions.sh
COPY assets/google/scripts/fetch_guacamole.sh /google/scripts/fetch_guacamole.sh
RUN /google/scripts/fetch_guacamole.sh

###############################################################
# Stage: Main System
###############################################################
FROM ${GCP_REGION}-docker.pkg.dev/cloud-workstations-images/predefined/base:${CWS_BASE_IMAGE_TAG}
ARG DEBIAN_FRONTEND
ARG GCP_REGION
ARG CWS_BASE_IMAGE_TAG
ARG INSTALL_TIGERVNC
ARG INSTALL_CHROME_REMOTE_DESKTOP
ARG APP_STARTUP_DELAY
ARG GUACAMOLE_VERSION
ARG CONTAINER_REGISTRY
ARG DEFAULT_ENABLE_AUDIO_INPUT
ARG CURL_OPTS
ARG DPKG_OPTS
ARG APT_OPTS
ARG BASE_PKGS
ARG CHROME_PKGS
ARG TIGERVNC_PKGS
ARG CRD_PKGS
ARG PURGE_PKGS
ARG HOLD_PKGS

ENV CONTAINER_REGISTRY="${CONTAINER_REGISTRY}"

COPY --from=asset-prep /assets/etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=asset-prep /assets/etc/apt/keyrings/ /etc/apt/keyrings/

RUN INSTALL_PKGS="$BASE_PKGS $CHROME_PKGS"; \
    if [ "$INSTALL_TIGERVNC" = "true" ]; then INSTALL_PKGS="$INSTALL_PKGS $TIGERVNC_PKGS"; fi; \
    if [ "$INSTALL_CHROME_REMOTE_DESKTOP" = "true" ]; then INSTALL_PKGS="$INSTALL_PKGS $CRD_PKGS"; fi; \
    apt-get update && apt-get upgrade -y && apt-get purge -y ${PURGE_PKGS} && apt-mark hold ${HOLD_PKGS} && \
    apt-get install ${APT_OPTS} ${DPKG_OPTS} $INSTALL_PKGS && \
    dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    apt-get remove -y gnome-initial-setup cloud-init && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=asset-prep /assets/ /
RUN rm -rf /var/www/html/*
COPY --from=base-provider /export/ /
COPY --from=fetcher /downloads/ /

ARG APP_STARTUP_DELAY
ARG BACKEND_PROXY_PATH="/guacamole/"
ARG GUACAMOLE_VERSION
ARG CONTAINER_REGISTRY
ARG DEFAULT_ENABLE_AUDIO_INPUT
ARG DEFAULT_CLIENT_PROTOCOL
ARG SUPPORTED_PROTOCOLS

ENV GCP_REGION="${GCP_REGION}"
ENV CWS_BASE_IMAGE_TAG="${CWS_BASE_IMAGE_TAG}"
ENV GUACAMOLE_VERSION="${GUACAMOLE_VERSION}"
ENV ENABLE_TIGERVNC=${INSTALL_TIGERVNC}
ENV ENABLE_CRD=${INSTALL_CHROME_REMOTE_DESKTOP}
ENV DEFAULT_ENABLE_AUDIO_INPUT=${DEFAULT_ENABLE_AUDIO_INPUT}
ENV DEFAULT_PROTOCOL="RDP"
ENV DEFAULT_CLIENT_PROTOCOL=${DEFAULT_CLIENT_PROTOCOL}
ENV SUPPORTED_PROTOCOLS=${SUPPORTED_PROTOCOLS}
ENV APP_STARTUP_DELAY=${APP_STARTUP_DELAY}
ENV BACKEND_PROXY_PATH="${BACKEND_PROXY_PATH}"

RUN /google/scripts/build/configure_workstation.sh

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
