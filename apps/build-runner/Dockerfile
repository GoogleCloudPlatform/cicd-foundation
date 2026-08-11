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

# Global ARGs for instructions
ARG ALPINE_VERSION=3.19
ARG SKAFFOLD_VERSION=v2.18.1

###############################################################
# Stage: Fetcher (Download tools)
###############################################################
FROM alpine:${ALPINE_VERSION} AS fetcher

ARG ANTIGRAVITY_CLI_VERSION=1.1.5
ARG ANTIGRAVITY_CLI_SHA256=1d586501b8a13d146e8aa3c7f00634f50c6034e2c428ea7d013377d36315a69a
ARG ANTIGRAVITY_SDK_VERSION=0.1.7
ARG ANTIGRAVITY_SDK_SHA256=8d4db60ac9873881a2406dcdcb26f1cc3e4ad795384cf8d1aea051f540b86d2b
ARG CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"

RUN apk add --no-cache curl tar

WORKDIR /downloads

# Download and extract Antigravity CLI
RUN curl ${CURL_OPTS} "https://github.com/google-antigravity/antigravity-cli/releases/download/${ANTIGRAVITY_CLI_VERSION}/agy_cli_linux_x64.tar.gz" -o agy_cli.tar.gz && \
    echo "${ANTIGRAVITY_CLI_SHA256}  agy_cli.tar.gz" | sha256sum -c - && \
    mkdir -p usr/local/bin && \
    tar -xzf agy_cli.tar.gz -C usr/local/bin antigravity && \
    mv usr/local/bin/antigravity usr/local/bin/antigravity-cli && \
    ln -s antigravity-cli usr/local/bin/agy && \
    rm agy_cli.tar.gz

# Download and extract Antigravity SDK
RUN curl ${CURL_OPTS} "https://github.com/google-antigravity/antigravity-sdk-python/archive/refs/tags/v${ANTIGRAVITY_SDK_VERSION}.tar.gz" -o agy_sdk.tar.gz && \
    echo "${ANTIGRAVITY_SDK_SHA256}  agy_sdk.tar.gz" | sha256sum -c - && \
    mkdir -p opt/antigravity-sdk && \
    tar -xzf agy_sdk.tar.gz -C opt/antigravity-sdk --strip-components=1 && \
    rm agy_sdk.tar.gz


###############################################################
# Stage: Main System
###############################################################
FROM gcr.io/k8s-skaffold/skaffold:${SKAFFOLD_VERSION}
USER root

ARG DEVCONTAINER_CLI_VERSION=0.88.0
ARG EXTRA_PKGS="curl nodejs npm python3 python3-pip"

# Map to ENVs for the installer and runtime
ENV EXTRA_PKGS=${EXTRA_PKGS}
ENV DEVCONTAINER_CLI_VERSION=${DEVCONTAINER_CLI_VERSION}
ENV PYTHONPATH="${PYTHONPATH}:/opt/antigravity-sdk"

# Copy fetched Antigravity assets
COPY --from=fetcher /downloads/ /

# Merge modular assets and build hooks into the container.
COPY assets/ /

# Run centralized configuration and cleanup
RUN /bin/bash /google/scripts/build/configure_runner.sh
