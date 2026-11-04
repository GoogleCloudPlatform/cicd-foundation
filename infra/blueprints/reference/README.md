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

This blueprint implements an enterprise multi-environment (`DEV`, `TEST`, `PROD`) software supply chain and runtime platform on Google Cloud.

## Architecture

The blueprint reflects enterprise architecture best practices:
- **Hub & Spoke Network Architecture**: Centralized hub VPC peered with spoke runtime VPCs, connected to build VPCs via HA VPN for non-transitive PSA routing.
- **Resource Management**: Dedicated GCP folders and segmented projects for Hub host/supplychain, and Prod/Test/Dev host, supplychain, and runtime service environments.
- **Runtime Compute**: Dedicated GKE Autopilot clusters per stage in isolated service projects.
- **Supply Chain Automation (`cicd_foundation`)**:
  - Instantiates `module.cicd_foundation` in `project_hub_supplychain`.
  - Multi-stage Cloud Deploy targets and delivery pipelines across dev, test, and prod.
  - Private Cloud Build worker pools per stage connected to build VPCs.
  - Binary Authorization with vulnerability attestor, KMS signing keys, and stage-specific policies.
  - Cloud Workstations for developers with persistent disks and Code-OSS.

## Prerequisites

- A Google Cloud Organization.
- Organization Administrator and Folder Administrator IAM permissions.
- Pre-created or automatically provisioned folders and projects.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Set `org_id`, folder IDs, project IDs, and developer identities.
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```
