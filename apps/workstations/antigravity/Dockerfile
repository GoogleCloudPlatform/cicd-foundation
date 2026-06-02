# syntax=docker/dockerfile:1.4

# Copyright 2025-2026 Google LLC
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

# This image layers the Antigravity application onto the GNOME foundation.

# The BASE_IMAGE is resolved by Skaffold.
ARG BASE_IMAGE

FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive
ARG INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON=true
ARG ANTIGRAVITY_PKGS="antigravity"

ENV INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON=${INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON}
# Register packages for centralized installation
ENV EXTRA_PKGS=${ANTIGRAVITY_PKGS}
ENV WORKSTATION_DEFAULT_APP="antigravity"

# Merge assets into the container
COPY assets/ /

# Perform centralized workstation configuration (hooks, packages, and integration).
RUN /google/scripts/build/configure_workstation.sh
