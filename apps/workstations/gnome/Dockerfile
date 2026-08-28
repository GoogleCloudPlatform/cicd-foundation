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
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG DPKG_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
ARG APT_OPTS="-y --no-install-recommends"
ARG GUI_PKGS="fonts-dejavu fonts-liberation fonts-ubuntu gir1.2-dbusmenu-glib-0.4 gir1.2-dbusmenu-gtk3-0.4 gnome-control-center gvfs-backends ubuntu-desktop-minimal gnome-remote-desktop"

RUN apt-get update && apt-get upgrade -y && \
    apt-get install ${APT_OPTS} ${DPKG_OPTS} ${GUI_PKGS} && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY assets/ /

RUN /google/scripts/build/configure_workstation.sh
