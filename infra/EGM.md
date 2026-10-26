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

# Infrastructure as Code (`infra`)

## Overview

Contains the Terraform configurations, reusable modules, deployable blueprints,
and architectural topologies (`reference` multi-project hub-and-spoke and
`simplified` single-project hub-and-team) that provision Google Cloud
Workstations, CI/CD pipelines (Cloud Build, Cloud Deploy, Artifact Registry,
Secure Source Manager, Cloud Scheduler), Binary Authorization/KMS supply-chain
security, VPC networking, and GKE Autopilot/Cloud Run runtime environments.

## Subdirectories & Boundaries

- [Blueprints (`blueprints`)](./blueprints/EGM.md): Deployable Terraform root
  blueprints, including the [`workstations`](./blueprints/workstations/EGM.md)
  blueprint for provisioning Cloud Workstations, VPC/NAT/firewall networking,
  IAM bindings, Android build matrices, and custom container image CI/CD
  pipelines.
- [Modules (`modules`)](./modules/EGM.md): Reusable Terraform modules
  ([`cicd_foundation`](./modules/cicd_foundation/EGM.md),
  [`cicd_pipelines`](./modules/cicd_pipelines/EGM.md), and
  [`cicd_workstations`](./modules/cicd_workstations/EGM.md)) and build/review
  helper scripts
  ([`cicd_pipelines/scripts`](./modules/cicd_pipelines/scripts/EGM.md)).
- [Reference Architecture (`reference`)](./reference/EGM.md): Multi-folder,
  11-project hub-and-spoke enterprise reference architecture with Shared VPCs,
  hub-to-spoke VPC peerings, HA VPN build-to-runtime bridges, private Cloud
  Build worker pools, Binary Authorization, Cloud Workstations, and GKE
  Autopilot/Cloud Run targets across `DEV`, `TEST`, and `PROD`.
- [Simplified Architecture (`simplified`)](./simplified/EGM.md):
  Single-project orchestration composing a shared infrastructure
  [`hub`](./simplified/hub/EGM.md) and per-developer isolated
  [`team`](./simplified/team/EGM.md) environments.
