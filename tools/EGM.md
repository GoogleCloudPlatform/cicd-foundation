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

# Tools (`tools`)

## Overview

Groups CI/CD and deployment tooling configurations and installation scripts for
Cloud Build, Cloud Deploy, Kritis, and Tekton.

## Subdirectories & Boundaries

- **Tekton**: [`./tekton/EGM.md`](./tekton/EGM.md) - Provisions Tekton
  Pipelines, Tekton Triggers, Interceptors, catalog tasks, and local
  task/pipeline manifests onto a Kubernetes cluster via `installation.sh`.
- **Cloud Build**: [`./cloudbuild/README.md`](./cloudbuild/README.md) -
  Configuration files for Cloud Build integration (non-code asset directory).
- **Cloud Deploy**: [`./clouddeploy/README.md`](./clouddeploy/README.md) -
  Configuration files for Cloud Deploy pipelines (non-code asset directory).
- **Kritis** (`./kritis`): Binary Authorization / Kritis signer configuration
  manifests (non-code asset directory).
