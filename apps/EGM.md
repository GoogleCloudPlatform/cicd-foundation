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

# Applications & Workstation Container Layers (`apps`)

## Overview

Groups the repository's sample Cloud Run and Kubernetes applications, custom
Cloud Build / Skaffold build runner image, Development Container
(`devcontainer.json`) configurations, and layered Google Cloud Workstations
container images and runtime tooling.

## Subdirectories & Boundaries

- `build-runner`: [`./build-runner/EGM.md`](./build-runner/EGM.md) -
  Multi-stage Docker build (`Dockerfile`) and root filesystem overlay
  (`assets/`) for the custom Cloud Build and Skaffold runner image
  (`build-runner`) packaging the Antigravity CLI (`agy`), Antigravity Python
  SDK, `@devcontainers/cli`, and the `build_devcontainer` helper script.
- `devcontainers`: [`./devcontainers/EGM.md`](./devcontainers/EGM.md) -
  Collection of Development Container (`devcontainer.json`) and Skaffold
  project configurations (`gvisor-antigravity`, `intellij`, `node-demo`) for
  building and testing isolated development environments inside Cloud
  Workstations.
- `go-hello-world`: [`./go-hello-world/EGM.md`](./go-hello-world/EGM.md) -
  Skaffold application package that builds a sample Go HTTP server
  (`src/go-hello-world`) using `ko` and deploys environment-specific
  Kubernetes and Knative manifests (`envs/base`, `envs/dev`, `envs/test`,
  `envs/prod`) via Kustomize and `kubectl`.
- `java-hello-world`:
  [`./java-hello-world/EGM.md`](./java-hello-world/EGM.md) - Skaffold
  application package that builds a Java 17 Spring Boot web service
  (`src/java-hello-world`) using Google Cloud Buildpacks and deploys
  environment-specific Kubernetes and Knative manifests via Kustomize and
  `kubectl`.
- `node-hello-world`:
  [`./node-hello-world/EGM.md`](./node-hello-world/EGM.md) - Skaffold
  application package that builds a Node.js Express web service
  (`src/node-hello-world`) using Google Cloud Buildpacks and deploys
  environment-specific Kubernetes and Knative manifests via Kustomize and
  `kubectl`.
- `python-hello-world`:
  [`./python-hello-world/EGM.md`](./python-hello-world/EGM.md) - Skaffold
  application package that builds a Python Flask web service
  (`src/python-hello-world`) using Google Cloud Buildpacks and deploys
  environment-specific Kubernetes and Knative manifests via Kustomize and
  `kubectl`.
- `workstations`: [`./workstations/EGM.md`](./workstations/EGM.md) - Cloud
  Workstations container image layers and runtime tooling, including the
  `common` base layer (`setup-workstation` Go CLI and build/startup hooks),
  `preflight` readiness gate, `preflight-web` Single-Page Application, `gnome`
  desktop layer (with native RDP via `grdctl`), `remote-desktop` (Apache
  Guacamole, TigerVNC, Chrome Remote Desktop, WebSocket audio bridge), and IDE
  layers (`android-studio-for-platform`, `antigravity`, `antigravity2`,
  `intellij`, `codeoss`, `codeoss-devcontainer-intellij`,
  `codeoss-devcontainer-gvisor-terraform`).
