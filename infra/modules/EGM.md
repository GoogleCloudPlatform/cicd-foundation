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

# Reusable Infrastructure Modules (`modules`)

## Overview

Contains reusable Terraform modules under `infra/modules` for provisioning
Google Cloud-native CI/CD delivery pipelines, Cloud Workstations
clusters/configurations/instances, and unified foundation environments.

## Subdirectories & Boundaries

- [CI/CD Foundation (`cicd_foundation`)](./cicd_foundation/EGM.md):
  Orchestrates [`cicd_pipelines`](./cicd_pipelines/EGM.md) and
  [`cicd_workstations`](./cicd_workstations/EGM.md) to unify application
  delivery pipelines with custom Cloud Workstation container image build
  pipelines and workstation configuration hydration.
- [CI/CD Pipelines (`cicd_pipelines`)](./cicd_pipelines/EGM.md): Provisions
  Artifact Registry, Secure Source Manager (SSM), Cloud Build triggers/worker
  pools (with transitive Skaffold dependency resolution and optional Gemini
  agentic pre-build reviews), Cloud Deploy pipelines/targets, Binary
  Authorization/KMS attestation, and Cloud Scheduler rebuild jobs.
- [CI/CD Workstations (`cicd_workstations`)](./cicd_workstations/EGM.md):
  Provisions Cloud Workstations clusters, workstation configurations,
  workstation instances, dedicated host service accounts, and IAM policies for
  creators and users.
