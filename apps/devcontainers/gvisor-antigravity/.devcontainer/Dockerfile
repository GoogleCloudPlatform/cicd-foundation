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

FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm

ARG ANTIGRAVITY_CLI_VERSION=1.0.7
ARG ANTIGRAVITY_CLI_SHA256=f5bb465edb938212eb0a185d68c420ff5b78f08c72de5a6d88dfefaf7af17074
ARG ANTIGRAVITY_SDK_VERSION=0.1.3
ARG ANTIGRAVITY_SDK_SHA256=74bd6f2c2e015de082cb39a6714cc344880657469532940d679451c779f8a660

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

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
