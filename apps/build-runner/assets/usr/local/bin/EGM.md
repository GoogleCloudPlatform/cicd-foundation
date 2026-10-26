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

# bin

## Overview

Provides the `build_devcontainer` CLI utility script packaged into
`/usr/local/bin` of the `build-runner` image for building and pushing
Development Container images to Artifact Registry. It conditionally enables
BuildKit registry caching depending on whether the target workspace's
devcontainer configuration defines `"features"`.

## Interface

- `build_devcontainer <image_tag> [workspace_folder]`: Executable Bash CLI
  script for building and pushing a devcontainer image.
- `find_repo_root <dir>`: Shell helper that walks up parent directories from
  `<dir>` to locate the repository root containing `skills/common.sh`.
- `has_devcontainer_features <config_file>`: Shell helper that inspects a
  `devcontainer.json` file for an uncommented `"features"` key.
- `main <image_tag> [workspace_folder]`: Main entrypoint function
  orchestrating builder selection, `devcontainer build`, and `docker push`.

## Invariants

- Executes under strict shell error handling (`set -euo pipefail`).
- Requires a target image name/tag as the first positional argument (`$1`);
  defaults `workspace_folder` (`$2`) to `.`.
- Requires `skills/common.sh` to exist in an ancestor directory of the current
  working directory (`pwd`) when executed.
- Derives the registry cache reference (`cache_ref`) by appending `-cache` to
  `<image_tag>`.
- Disables BuildKit registry caching (`--cache-from` / `--cache-to`) and
  switches to the `default` Docker Buildx builder if
  `.devcontainer/devcontainer.json` or `.devcontainer.json` in the workspace
  contains an uncommented `"features"` key.

## Side Effects

- Sources `${PROJECT_ROOT}/skills/common.sh` on script load.
- Creates or switches the active Docker Buildx builder (`docker buildx use
default` when features are detected, or `docker buildx create --use --driver
docker-container --name devcontainer-builder || docker buildx use
devcontainer-builder` otherwise).
- Builds a devcontainer image via `devcontainer build` (importing and
  exporting registry cache layers via `<image_tag>-cache` when features are
  not used).
- Pushes the built container image (`<image_tag>`) to the container registry
  via `docker push`.
