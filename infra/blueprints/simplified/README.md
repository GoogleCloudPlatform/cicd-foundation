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

# Simplified Blueprint (`simplified`)

This blueprint provisions a single-project CI/CD Foundation environment on Google Cloud. It is ideal for workshops, proof-of-concepts, and developer onboarding sandbox setups.

## Architecture

The blueprint deploys:
- **Networking**: A single VPC with subnets for dev, test, and prod workloads, Cloud NAT, and firewall rules.
- **Compute / Runtime**: GKE Autopilot clusters for `dev`, `test`, and `prod` stages with dedicated service accounts.
- **CI/CD Foundation (`cicd_foundation`)**:
  - Cloud Build triggers (GitHub or Secure Source Manager).
  - Cloud Deploy delivery pipelines and targets for GKE, Cloud Run, and Agentic runtimes.
  - Binary Authorization attestors and policies with KMS vulnerability signing keys.
  - Cloud Workstations cluster, configuration, and developer instances.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Populate `project_id`, `region`, and developer identities.
3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```
