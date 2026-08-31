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

###############################################################
# Stage: intellij-devcontainer-in-codeoss
###############################################################
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

# Merge layer assets into the workstation container
COPY assets/ /

# Copy devcontainer configuration as image template
COPY .devcontainer/ /opt/devcontainer/intellij/

# Run centralized workstation configuration (executes build hooks)
RUN /google/scripts/build/configure_workstation.sh

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
