# syntax=docker/dockerfile:1

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG IMAGE=us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base
ARG TAG=latest

FROM ${IMAGE}:${TAG}

#######################################################################

# cf. https://developer.android.com/studio/index.html
ARG ANDROID_STUDIO_VERSION=2024.1.1.11
ARG ANDROID_STUDIO_SHA256=d8fa8ecfe415b44513350901501e2a0f429ca033cf1805054b1c816c4a704565
ARG COMMANDLINETOOLS_VERSION=11076708
ARG COMMANDLINETOOLS_SHA256=2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258

ARG SDK_LEVEL=34
ARG BUILD_TOOLS_LEVEL=34.0.0

#######################################################################

ARG DISTRO=jammy

ARG ANDROID_STUDIO_FILE=android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz
ARG ANDROID_STUDIO_IMAGE=https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/${ANDROID_STUDIO_FILE}

ARG COMMANDLINETOOLS_FILE=commandlinetools-linux-${COMMANDLINETOOLS_VERSION}_latest.zip
ARG COMMANDLINETOOLS_URL=https://dl.google.com/android/repository/${COMMANDLINETOOLS_FILE}

ARG DEST_DIR=/opt/google/

# Install Android Studio
RUN mkdir -p ${DEST_DIR} \
  && \
  wget ${ANDROID_STUDIO_IMAGE} \
  && \
  echo "SHA256 (${ANDROID_STUDIO_FILE}) = ${ANDROID_STUDIO_SHA256}" | sha256sum -c - \
  && \
  tar -xzvf ${ANDROID_STUDIO_FILE} -C ${DEST_DIR} \
  && \
  rm ${ANDROID_STUDIO_FILE} \
  || \
  exit 1

# Install commandlinetools
RUN wget ${COMMANDLINETOOLS_URL} \
  && \
  echo "SHA256 (${COMMANDLINETOOLS_FILE}) = ${COMMANDLINETOOLS_SHA256}" | sha256sum -c - \
  && \
  unzip ${COMMANDLINETOOLS_FILE} -d ${DEST_DIR} \
  && \
  rm ${COMMANDLINETOOLS_FILE} \
  || \
  exit 2

ARG SDK_ROOT=${DEST_DIR}android-sdk

# NOTE: In this prototype we are setting the SDK location on ephemeral disk
# which allows the image administrator to dictate which packages are available
# in the image. It may be more useful for customers to persist the SDKs in
# their home directory at the cost requiring an initial download, or some
# startup script that does some management of installed SDKs.
RUN mkdir ${SDK_ROOT} \
  && \
  chmod o+w ${SDK_ROOT} \
  || \
  exit 3

# Install default packages
ENV PATH=$PATH:${DEST_DIR}cmdline-tools/bin
RUN yes | sdkmanager --sdk_root=${SDK_ROOT} --install "platforms;android-${SDK_LEVEL}" \
  && \
  yes | sdkmanager --sdk_root=${SDK_ROOT} --install "platform-tools" \
  && \
  yes | sdkmanager --sdk_root=${SDK_ROOT} --install "build-tools;${BUILD_TOOLS_LEVEL}" \
  && \
  yes | sdkmanager --sdk_root=${SDK_ROOT} --install "sources;android-${SDK_LEVEL}" \
  && \
  yes | sdkmanager --sdk_root=${SDK_ROOT} --install "system-images;android-${SDK_LEVEL};google_apis;x86_64" \
  && \
  chown -R :users ${SDK_ROOT} \
  || \
  exit 4

# Configure a profile script to set Android Studio environment variables.
RUN echo "export ANDROID_SDK_ROOT=${SDK_ROOT}/" > /etc/profile.d/android_studio_envs.sh \
  && \
  echo "export ANDROID_HOME=${SDK_ROOT}/" >> /etc/profile.d/android_studio_envs.sh \
  || \
  exit 5

ARG XPRA_SOURCES_URL=https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/${DISTRO}/xpra.sources

# Install minimal xpra packages required to run a seamless session in a browser.
RUN wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc \
  && \
  wget -O "/etc/apt/sources.list.d/xpra.sources" ${XPRA_SOURCES_URL} \
  && \
  apt-get update && apt-get install -y --no-install-recommends \
    xpra \
    xpra-x11 \
    xpra-html5 \
    python3-requests \
  || \
  exit 6

# cf. https://cloud.google.com/workstations/docs/customize-container-images#container_image_that_enables_x11_forwarding_for_ssh_sessions
# Permit X11 forwarding using only IPv4
RUN cat >> /etc/ssh/sshd_config <<-EOF

AddressFamily inet
X11Forwarding yes
EOF

ARG STARTUP_DIR=/etc/workstation-startup.d/
ARG STARTUP_SCRIPT=110_android_studio.sh

# Add startup script to run Android Studio.
COPY ${STARTUP_SCRIPT} ${STARTUP_DIR}
RUN chmod 755 ${STARTUP_DIR}${STARTUP_SCRIPT}

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
