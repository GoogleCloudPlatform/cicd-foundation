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

#################
# NOTE: This dockerfile uses heredoc syntax (indicated in the first line of this
# dockerfile). Ensure you set DOCKER_BUILDKIT=1 when building:
# DOCKER_BUILDKIT=1 docker build -t $REPO_REGION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/$REPO_NAME/$APP_NAME .
################

FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base

# Install Android Studio
RUN mkdir -p /opt/google && \
  wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.27/android-studio-2023.1.1.27-linux.tar.gz && \
  tar -xzvf android-studio-2023.1.1.27-linux.tar.gz -C /opt/google/ && \
  rm android-studio-2023.1.1.27-linux.tar.gz && \
  wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip && \
  unzip commandlinetools-linux-10406996_latest.zip -d /opt/google/ && \
  rm commandlinetools-linux-10406996_latest.zip && \
  # NOTE: In this prototype we are setting the SDK location on ephemeral disk
  # which allows the image administrator to dictate which packages are available
  # in the image. It may be more useful for customers to persist the SDKs in
  # their home directory at the cost requiring an initial download, or some
  # startup script that does some management of installed SDKs.
  mkdir /opt/google/android-sdk && \
  chmod o+w /opt/google/android-sdk

# Install default packages
ENV PATH=$PATH:/opt/google/cmdline-tools/bin
RUN yes | sdkmanager --sdk_root=/opt/google/android-sdk --install "platforms;android-34" && \
  yes | sdkmanager --sdk_root=/opt/google/android-sdk --install "platform-tools" && \
  yes | sdkmanager --sdk_root=/opt/google/android-sdk --install "build-tools;34.0.0" && \
  yes | sdkmanager --sdk_root=/opt/google/android-sdk --install "sources;android-34" && \
  yes | sdkmanager --sdk_root=/opt/google/android-sdk --install "system-images;android-34;google_apis;x86_64" && \
  # Grant users permissions to the sdk_root.
  chown -R :users /opt/google/android-sdk

# Configure a profile script to set Android Studio environment variables.
RUN echo "export ANDROID_SDK_ROOT=/opt/google/android-sdk/" > /etc/profile.d/android_studio_envs.sh && \
  echo "export ANDROID_HOME=/opt/google/android-sdk/" >> /etc/profile.d/android_studio_envs.sh

# Install minimal xpra packages required to run a seamless session in a browser.
RUN curl http://xpra.org/gpg.asc | apt-key add - && \
  echo "deb http://xpra.org/ focal main" >> /etc/apt/sources.list.d/xpra.list && \
  apt-get update && apt-get install -y --no-install-recommends \
    xpra \
    xpra-x11 \
    xpra-html5 \
    python3-requests

# Add a startup to run Android studio under xpra.
RUN cat >> /etc/workstation-startup.d/110_android_studio.sh <<-EOF
echo "Starting xpra server, session will terminate when Android Studio is Closed."

function start_android_studio {
  runuser user -c -l "xpra start --min-port=80 --bind-tcp=0.0.0.0:80 --html=on --exit-with-children=yes --systemd-run=no --daemon=no --start-child-after-connect=/opt/google/android-studio/bin/studio.sh"
}

function kill_container {
  echo "Android Studio exited, terminating container."
  ps x | awk {'{print \$1}'} | awk 'NR > 1' | xargs kill
}

(start_android_studio || kill_container)&
EOF

RUN chmod 755 /etc/workstation-startup.d/110_android_studio.sh

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
