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

# Reference Architecture Blueprint (`reference`)

This blueprint implements an enterprise hub-and-spoke multi-environment software supply chain and runtime platform on Google Cloud. Spoke environments (e.g., `dev`, `test`, `prod`, or custom stages) are parameterized via `var.environments` and ordered deterministically in Cloud Deploy via each stage's `order` attribute.

## Architecture

The blueprint reflects enterprise architecture best practices:
- **Hub & Spoke Network Architecture**: Centralized Hub VPC peered with per-environment spoke runtime VPCs, each connected to an isolated build VPC via HA VPN for non-transitive Private Service Access (PSA) routing.
- **Resource Management**: Dedicated GCP folders and segmented projects for Hub (`project_hub_host`, `project_hub_supplychain`) and each spoke environment (`projects.host`, `projects.supplychain`, `projects.service`).
- **Runtime Compute**: Dedicated GKE Autopilot clusters and Cloud Run targets per spoke environment in isolated service projects.
- **Supply Chain Automation (`cicd_foundation`)**:
  - Instantiates `module.cicd_foundation` (`v9.0.0`) in `project_hub_supplychain`.
  - Multi-stage Cloud Deploy targets and serial delivery pipelines ordered by `environments[*].order`.
  - Private Cloud Build worker pools per spoke environment connected to build VPCs.
  - Binary Authorization with vulnerability attestor, KMS signing keys, and per-environment runtime project policies.
  - Cloud Workstations in the Hub Shared VPC for developers with persistent disks and Code-OSS.

## Prerequisites

- A Google Cloud Organization.
- Organization Administrator and Folder Administrator IAM permissions.
- Pre-created or automatically provisioned folders (`folders_create`) and projects (`projects_create`).

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Set `org_id`, Hub folder/project IDs, `environments` (folders, project IDs, CIDRs, and stage policies), and `developers`.
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```
