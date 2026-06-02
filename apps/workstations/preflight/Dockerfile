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

ARG PREFLIGHT_WEB_REPO=""
ARG PREFLIGHT_WEB_DIR=""

ARG ALPINE_VERSION=3.19
ARG NODE_VERSION=20-slim

###############################################################
# Stage: web-builder
###############################################################
FROM node:${NODE_VERSION} AS web-builder
ARG PREFLIGHT_WEB_REPO
ARG PREFLIGHT_WEB_DIR
WORKDIR /build/web
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
COPY preflight-web/ ./source/
COPY preflight/assets/google/scripts/build/build_web.sh ./build_web.sh
COPY preflight/docs/privacy_notice.md ./preflight/docs/
RUN ./build_web.sh "${PREFLIGHT_WEB_REPO}" "${PREFLIGHT_WEB_DIR}"

###############################################################
# Stage: Preflight Provider
###############################################################
FROM alpine:${ALPINE_VERSION}
COPY preflight/assets/ /export/
COPY --from=web-builder /build/web/dist/ /export/var/www/html/
