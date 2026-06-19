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

ARG GOLANG_VERSION=1.22
ARG ALPINE_VERSION=3.19
ARG NODE_VERSION=20-slim
ARG CHEZMOI_VERSION=2.70.5
ARG CHEZMOI_SHA256=6a76a0ac3718f0d45b34b4b57067f9556f8f6042e3da710a3c496838362aca14
ARG CURL_OPTS="-fsSL --retry 3 --connect-timeout 10 --max-time 300"

###############################################################
# Stage: setup-builder
###############################################################
FROM golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS setup-builder
WORKDIR /app
COPY preflight/tools/setup-workstation/go.mod preflight/tools/setup-workstation/go.sum ./
RUN go mod download
COPY preflight/tools/setup-workstation/main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /setup-workstation main.go

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
ARG CHEZMOI_VERSION
ARG CHEZMOI_SHA256
ARG CURL_OPTS

RUN apk add --no-cache curl tar && \
    curl ${CURL_OPTS} "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" -o chezmoi.tar.gz && \
    echo "${CHEZMOI_SHA256}  chezmoi.tar.gz" | sha256sum -c - && \
    mkdir -p /export/google/bin && \
    tar -xzf chezmoi.tar.gz -C /export/google/bin chezmoi && \
    rm chezmoi.tar.gz && \
    apk del curl tar

COPY preflight/assets/ /export/
COPY --from=web-builder /build/web/dist/ /export/var/www/html/
COPY --from=setup-builder /setup-workstation /export/google/bin/setup-workstation
