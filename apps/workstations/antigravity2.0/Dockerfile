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

# This image layers the Antigravity 2.0 application onto the GNOME foundation.

# The BASE_IMAGE is resolved by Skaffold.
ARG BASE_IMAGE

FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive
ARG ANTIGRAVITY_VERSION=1.0.7
ARG CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"

ENV ANTIGRAVITY_VERSION=${ANTIGRAVITY_VERSION}
ENV WORKSTATION_DEFAULT_APP="antigravity"

# Fetch Antigravity 2.0 from GCS
RUN mkdir -p /opt/antigravity && \
    curl ${CURL_OPTS} "https://storage.googleapis.com/antigravity-public/products/antigravity/${ANTIGRAVITY_VERSION}/antigravity_linux_x64.tar.gz" | \
    tar -xz -C /opt/antigravity && \
    ln -s /opt/antigravity/antigravity /usr/local/bin/antigravity

# Merge assets into the container
COPY assets/ /

# Perform centralized workstation configuration (hooks, packages, and integration).
RUN /google/scripts/build/configure_workstation.sh
