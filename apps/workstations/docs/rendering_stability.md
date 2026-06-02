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

# Rendering Stability Guide (GPU & Headless)

This guide describes the standardized approach for ensuring graphical applications (Electron, Chromium, etc.) run stably in both GPU-enabled and headless (CPU-only) Cloud Workstations environments.

## The Challenge

Cloud Workstations can be configured with or without attached GPUs. Applications that rely on hardware acceleration often crash or render incorrectly (e.g., solid gray windows) when running in a headless Wayland session without a GPU, unless specific stability flags are provided.

## Centralized GPU Detection

The blueprint provides a centralized environment variable, `WORKSTATION_GPU_ENABLED`, defined in `/google/scripts/common.sh`. This variable is automatically set to `true` or `false` during workstation startup based on the presence of `/dev/dri` or `/dev/nvidia0`.

## The "Shadowing Wrapper" Pattern

To support both GPU and non-GPU configurations without modifying original package files, we use the **Shadowing Wrapper** pattern:

1.  **Wrapper Script**: Create a bash script in `/usr/local/bin/` with the same name as the target application (e.g., `google-chrome-stable`).
2.  **Conditional Logic**: The script sources `common.sh` and applies stability flags ONLY if `WORKSTATION_GPU_ENABLED` is `false`.
3.  **PATH Priority**: Since `/usr/local/bin` precedes `/usr/bin` in the system `$PATH`, both terminal users and desktop entries will automatically use the wrapper.

### Example Wrapper Script

```bash
#!/bin/bash
set -euo pipefail
source /google/scripts/common.sh

FLAGS=("--no-sandbox" "--ozone-platform=wayland")

if [[ "${WORKSTATION_GPU_ENABLED}" == "false" ]]; then
  # Flags for stable software rendering
  FLAGS+=("--disable-gpu" "--in-process-gpu" "--disable-gpu-sandbox")
fi

exec /usr/bin/original-binary "${FLAGS[@]}" "$@"
```

## Recommended Stability Flags

For Electron and Chromium-based applications in headless environments, the following flags are recommended:

| Flag                       | Purpose                                                                |
| :------------------------- | :--------------------------------------------------------------------- |
| `--ozone-platform=wayland` | Forces the Wayland backend (required for our GNOME session).           |
| `--disable-gpu`            | Disables hardware acceleration.                                        |
| `--in-process-gpu`         | Runs the GPU thread inside the browser process (prevents IPC crashes). |
| `--disable-gpu-sandbox`    | Disables the GPU sandbox (avoids SIGTRAP/133 errors).                  |
| `--disable-dev-shm-usage`  | Prevents crashes related to `/dev/shm` size limits in containers.      |

## Integrating with Desktop Entries

When using a wrapper, ensure the `.desktop` file points to the wrapper (usually just the binary name if it's in `/usr/local/bin`) rather than the absolute path to the original binary in `/usr/bin`.

```ini
[Desktop Entry]
Name=My App
Exec=my-app-name %U
```
