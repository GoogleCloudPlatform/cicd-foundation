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

ARG BASE_IMAGE
ARG BACKEND_PROXY_PATH="/"
ARG PORT=80
ARG DEFAULT_CLIENT_PROTOCOL="SSH"
ARG DEFAULT_REDIRECT_PATH="/"
ARG SUPPORTED_PROTOCOLS="SSH"
ARG INSTALL_GVISOR=true
ARG INSTALL_DEVCONTAINERS=true
ARG EXTRA_PKGS="apt-transport-artifact-registry curl gettext-base nginx systemd unzip nodejs openssh-server"
ARG PURGE_PKGS="apache2* php*"
ARG HOLD_PKGS="apache2 apache2-bin apache2-data apache2-utils php*"

FROM ${BASE_IMAGE} AS base-provider

FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest

ARG BACKEND_PROXY_PATH
ARG PORT
ARG DEFAULT_CLIENT_PROTOCOL
ARG DEFAULT_REDIRECT_PATH
ARG SUPPORTED_PROTOCOLS
ARG INSTALL_GVISOR
ARG INSTALL_DEVCONTAINERS
ARG EXTRA_PKGS
ARG PURGE_PKGS
ARG HOLD_PKGS

ENV BACKEND_PROXY_PATH=${BACKEND_PROXY_PATH}
ENV PORT=${PORT}
ENV DEFAULT_CLIENT_PROTOCOL=${DEFAULT_CLIENT_PROTOCOL}
ENV DEFAULT_REDIRECT_PATH=${DEFAULT_REDIRECT_PATH}
ENV SUPPORTED_PROTOCOLS=${SUPPORTED_PROTOCOLS}
ENV INSTALL_GVISOR=${INSTALL_GVISOR}
ENV INSTALL_DEVCONTAINERS=${INSTALL_DEVCONTAINERS}
ENV EXTRA_PKGS=${EXTRA_PKGS}
ENV PURGE_PKGS=${PURGE_PKGS}
ENV HOLD_PKGS=${HOLD_PKGS}

COPY --from=base-provider /export/ /
COPY assets/ /

RUN /google/scripts/build/configure_workstation.sh

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
