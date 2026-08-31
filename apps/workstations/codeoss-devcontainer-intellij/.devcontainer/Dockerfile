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

###############################################################
# Stage: intellij-devcontainer
###############################################################
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/intellij-ultimate:latest
ARG DEBIAN_FRONTEND=noninteractive

ARG ANTIGRAVITY_CLI_VERSION=1.1.22
ARG ANTIGRAVITY_CLI_SHA256=1e1a219a86e75d7c6351f96d182ca2105302d5c34d8fa9c31265dc0adf24145f
ARG ANTIGRAVITY_SDK_VERSION=0.1.15
ARG ANTIGRAVITY_SDK_SHA256=ae307d2fe7643a4d779dcc1160860413b55bfbfe549377e51f7e76e1b72f64e7

RUN apt-get update && apt-get install -y curl sudo && rm -rf /var/lib/apt/lists/*

# Ensure default 'user' (UID 1000) exists with passwordless sudo for devcontainer execution
RUN if id -u 1000 >/dev/null 2>&1; then \
        existing_user=$(id -nu 1000); \
        if [ "${existing_user}" != "user" ]; then \
            userdel -r "${existing_user}" 2>/dev/null || userdel "${existing_user}"; \
        fi; \
    fi && \
    if ! id -u user >/dev/null 2>&1; then \
        useradd -m -s /bin/bash -u 1000 -U -G sudo user && \
        echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user && \
        chmod 0440 /etc/sudoers.d/user; \
    fi

# Install Antigravity CLI
RUN curl -fsSL "https://github.com/google-antigravity/antigravity-cli/releases/download/${ANTIGRAVITY_CLI_VERSION}/agy_cli_linux_x64.tar.gz" -o cli.tar.gz && \
    echo "${ANTIGRAVITY_CLI_SHA256}  cli.tar.gz" | sha256sum -c - && \
    tar -xzf cli.tar.gz -C /usr/local/bin || tar -xzf cli.tar.gz -C /usr/local/bin && \
    (mv /usr/local/bin/antigravity /usr/local/bin/antigravity-cli && ln -s /usr/local/bin/antigravity-cli /usr/local/bin/agy) || true && \
    rm -f cli.tar.gz

# Install Antigravity SDK
RUN mkdir -p /opt/antigravity-sdk && \
    curl -fsSL "https://github.com/google-antigravity/antigravity-sdk-python/archive/refs/tags/v${ANTIGRAVITY_SDK_VERSION}.tar.gz" -o sdk.tar.gz && \
    echo "${ANTIGRAVITY_SDK_SHA256}  sdk.tar.gz" | sha256sum -c - && \
    tar -xzf sdk.tar.gz -C /opt/antigravity-sdk --strip-components=1 && \
    rm -f sdk.tar.gz

ENV PYTHONPATH="${PYTHONPATH:-}:/opt/antigravity-sdk"
