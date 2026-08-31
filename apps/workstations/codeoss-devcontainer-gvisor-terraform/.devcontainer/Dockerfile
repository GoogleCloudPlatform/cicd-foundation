FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
# Disable GCE check script during build to prevent hang
ENV CLOUD_WORKSTATIONS_ENABLE_METADATA_CREDS_CHECK=true

ARG GVISOR_VERSION=20260803.0
ARG GVISOR_X86_64_SHA512=266ff0c74ba4faf137837c051e1d3c0a331bb1d3c152d791f349ef6680542d089b81f68e3c9f196a6fb82263909cfc583c39e98a0e058bb29c5ab752d9432805
ARG GVISOR_AARCH64_SHA512=6548e3222a31b9f4029fd8ad4c78076ab336db9789f8fa0c68f3dbe410278b043e7dd18f283a44df248ac63b577082937777b727118af3388bec8c9cc9c931b8

# Install gVisor (runsc)
RUN apt-get update && apt-get install -y wget bzip2 && rm -rf /var/lib/apt/lists/* && \
    ARCH=$(uname -m) && \
    case "${ARCH}" in \
        x86_64) SHA="${GVISOR_X86_64_SHA512}" ;; \
        aarch64) SHA="${GVISOR_AARCH64_SHA512}" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    URL="https://storage.googleapis.com/gvisor/releases/release/${GVISOR_VERSION}/${ARCH}" && \
    wget ${URL}/gvisor.tar.bz2 && \
    echo "${SHA}  gvisor.tar.bz2" | sha512sum -c - && \
    tar -xjf gvisor.tar.bz2 -C /usr/local/bin && \
    rm -f gvisor.tar.bz2

# Configure the pre-installed Docker daemon to use runsc
RUN /usr/local/bin/runsc install
