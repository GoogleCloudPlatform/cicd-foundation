<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Dockerfile Style Guide

## Build-time (ARG) vs. Runtime (ENV) Configuration

To maximize the flexibility of the container image across different environments, strictly distinguish between build-time and runtime parameters:

1. **`ARG` (Build-Time):** Use `ARG` strictly for parameters that physically alter the image structure or the packages installed.
   - **Orchestration**: In this repository, `ARG` values are typically set by Skaffold's `buildArgs` block. Skaffold, in turn, retrieves these values from environment variables passed by Terraform.
   - **Defaults**: Always provide a sensible default for `ARG` in the Dockerfile (e.g., `ARG GCP_REGION=us-central1`) to allow for standalone `docker build` commands.
   - **Examples**: Package versions (`GUACAMOLE_VERSION`), toggles (`INSTALL_TIGERVNC`), or repository paths (`PREFLIGHT_WEB_REPO`).
2. **`ENV` (Runtime):** Use `ENV` for variables that dictate how the image behaves when the container is executed.
   - If a service is optional but its binaries are installed, use an `ENV` to toggle its startup (e.g., `ENABLE_TIGERVNC`, `ENABLE_AUDIO_INPUT`).
   - Pass build `ARG` defaults into the runtime environment by explicitly mapping them: `ENV ENABLE_TIGERVNC=${INSTALL_TIGERVNC}`.

This ensures a single, immutable image can be promoted through multiple environments while drastically altering its behavior simply by passing `-e` flags to `docker run`.

## APT & GPG Key Management

1.  **Secure, Scoped Trust Model**: To ensure a secure and modular build process, all third-party APT repositories **must** use a scoped trust model. This prevents a compromised key from being used to validate packages from any repository other than the one it is intended for.
2.  **Key Storage**: All GPG keys **must** be stored in the layer's `assets/etc/apt/keyrings/` directory. They will be copied into the final image at `/etc/apt/keyrings/`.
3.  **Source List Configuration**: Every `.list` file in `assets/etc/apt/sources.list.d/` **must** use the `[signed-by]` attribute to explicitly link the repository to its corresponding key.
4.  **Mandate**: All GPG keys **must** be pre-downloaded and stored as assets within the repository. Never download keys as part of the Docker build process itself (`apt-key add`, `gpg --recv-keys`, etc.).
5.  **Example (`google-chrome.list`)**:
    ```
    deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main
    ```

## Image Layer Optimization

1. **Combine RUN statements**: Chain `apt-get update`, `apt-get install`, and `rm -rf /var/lib/apt/lists/*` in a single `RUN` block to minimize layer size.
2. **Multi-stage Builds**: Use `FROM alpine AS fetcher` blocks for heavy network downloads (like `crane` pulls or `curl` downloads) so that build utilities and intermediate archives don't bloat the final production image.
3. **Centralized Configuration and Hook Pattern**: To maintain a clean and modular `Dockerfile`, move complex tool installations or configurations into external scripts in an `assets/build-hooks.d/` directory and use the centralized configuration utility.

   - **Mandate**: Every hook script must be executable and follow the [Bash Style Guide](bash.md).
   - **Implementation**: Utilize the persistent `/google/scripts/build/configure_workstation.sh` script to orchestrate the build. This script automatically handles region-based APT updates, installs packages from `EXTRA_PKGS`, installs `.deb` files from `EXTRA_DEB_URLS`, and executes all hooks in `/build-hooks.d/`. It also performs automatic cleanup of hook directories and an `apt-get clean`.
   - **Automatic Transport**: The centralized script automatically detects if any repository uses the `ar+` protocol and will install `apt-transport-artifact-registry` if needed. Child layers do not need to manage this dependency.
   - **Desktop Integration**: Use standard `.desktop` metadata for registration. The system automatically pins applications in the `IDE` or `Development` categories to the dock.
   - **Example**:

     ```dockerfile
     # Global ARGs for the FROM instruction
     ARG BASE_IMAGE

     FROM ${BASE_IMAGE}

     # Stage-specific ARGs for package lists
     ARG MY_TOOL_PKGS="my-tool-package"
     ARG OTHER_TOOLS_PKGS="other-tool"
     ARG MY_TOOL_DEB_URL="https://example.com/tool.deb"

     # Map to ENVs for the centralized installer
     ENV EXTRA_PKGS="${MY_TOOL_PKGS} ${OTHER_TOOLS_PKGS}"
     ENV EXTRA_DEB_URLS="${MY_TOOL_DEB_URL}"

     # Merge modular assets and build hooks into the container.
     COPY assets/ /

     # Run centralized configuration and cleanup
     RUN /google/scripts/build/configure_workstation.sh
     ```

## Formatting and Syntax

1. **Default Shell**: Avoid using the `SHELL ["/bin/bash", "-c"]` instruction in Dockerfiles. While it ensures consistency, it can cause build failures in multi-stage builds if invoked before `bash` is installed (e.g., in minimal Alpine-based fetcher stages).
   - **Guideline**: Rely on **shebangs** (`#!/bin/bash`) within your hook scripts and fetch scripts to ensure they execute with the correct interpreter.
   - **Explicit Execution**: When calling a script from a `RUN` command, use the script path directly (if executable) or call it with an explicit interpreter: `RUN /bin/bash /path/to/script.sh`.
   - **Compatibility**: Ensure inline `RUN` commands are POSIX-compliant to work across different base image shells (like `ash` in Alpine or `dash` in Debian).
2. **Global ARG Placement**: All `ARG` instructions used in `FROM` statements (global scope) MUST be placed at the absolute top of the Dockerfile. If multiple global `ARG`s exist, `BASE_IMAGE` MUST be the final `ARG` in that group to ensure a consistent vertical scan pattern across all image layers.
3. **Comment Formatting**: Every comment explaining a following instruction (like `ARG` or `ENV`) MUST be preceded by an empty line to maintain visual separation and improve readability.
4. **No Empty Line After FROM**: Do not place an empty line immediately after a `FROM` instruction. Group the `FROM` instruction with its initial stage configuration (like `ARG`, `WORKDIR`, `USER`, or `ENV`). Use empty lines to separate distinct logical blocks further down in the stage.
5. **Sort Multi-Line Arguments**: Sort multi-line lists (like `apt-get install` packages or `apk add` dependencies) alphabetically. This improves readability, reduces duplicate entries, and simplifies git diffs.
6. **Consistent Formatting**: Use a backslash (`\`) at the end of a line followed by a newline and consistent indentation (strictly **2 spaces**) for multi-line commands to maintain readability.
7. **Avoid `latest`**: Prefer pinning base images and packages to specific versions or use `ARG`s to ensure reproducible builds and clear upgrade paths.
8. **Stage Header Blocks**: Every `FROM` instruction must be preceded by a distinct comment block clearly labeling the stage. The block must consist of a top line of exactly 63 hash characters (`#`), a middle line containing `# Stage: <name>` (or a short description), and a bottom line of 63 hash characters.
   ```dockerfile
   ###############################################################
   # Stage: <stage-name-or-description>
   ###############################################################
   FROM <image>
   ```
9. **Syntax 1.4 and Heredocs**: Dockerfile syntax version 1.4 (`# syntax=docker/dockerfile:1.4`) supports Heredocs, which can greatly improve the readability of complex multi-line `RUN` scripts or inline file generation. **However**, due to a current limitation with the Google Cloud Build `skaffold` container image's included Docker version, Heredocs cannot be used yet in this repository. In any other unconstrained environment, Heredocs should be the preferred standard.

## Testing Docker Containers

We do not test the `Dockerfile` syntax itself; we test the runtime integrity of the final built image.

### How to Write Tests

1. **Service Viability**: Use integration tests to verify the container image successfully boots systemd and all expected background daemons (`dockerd`, `nginx`, `guacd`) transition to the `active` state.
2. **Volume Mounts and Permissions**: Verify that runtime configurations (like dynamically generated `ephemeral.env` files) have the precise permissions and ownership required by the container's unprivileged users.
3. **Network Readiness**: Test that the container successfully binds to the expected host ports (e.g., 80, 22, 3389).
