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

## Overview

The `infra/blueprints/simplified` blueprint provisions a consolidated, single-project CI/CD Foundation environment on Google Cloud. It establishes a VPC network with dev, test, and prod subnets, provisions GKE Autopilot clusters across all three stages, and instantiates the `cicd_foundation` module (`v9.0.0`, mirrored locally at [`../../modules/cicd_foundation`](../../modules/cicd_foundation/EGM.md)) to configure Cloud Build triggers, Cloud Deploy delivery pipelines and targets, Binary Authorization attestors, KMS keys, Secure Source Manager instances/repositories, and Cloud Workstations.

## Interface

- Inputs (Project & Region): `project_id` (required), `region` (default `"europe-north1"`), `ssm_region` (default `"europe-west4"`), `enable_apis` (default `true`).
- Inputs (Networking): `vpc_create` (default `true`), `vpc_hub_primary_cidr` (default `"10.8.0.0/16"`), `vpc_hub_psa_cidr` (default `"10.60.0.0/16"`), `proxy_only_subnet_cidr_block` (default `"10.127.0.0/16"`), `nat_name` (default `"nat"`).
- Inputs (GKE Runtimes): `cluster_name` (default `"gke"`), `cluster_release_channel` (default `"REGULAR"`), `cluster_min_version`, `cluster_deletion_protection` (default `false`), `sa_cluster_name` (default `"sa-gke"`), `cluster_roles`, `cluster_dev_network_config`, `cluster_test_network_config`, `cluster_prod_network_config`.
- Inputs (CI/CD & Workstations): `apps`, `runtimes`, `developers`, `github_owner`, `github_repo`, `git_branch_trigger`, `git_branch_trigger_regexp`, `kritis_signer_image`, `secure_source_manager_always_create`, `ssm_branch_rule`, `cws_custom_images`, `machine_type_default`, `boot_disk_size_gb_default`, `idle_timeout_seconds_default`.
- Outputs: `cloud_build_trigger_ids`, `cloud_build_trigger_trigger_ids`, `cws_clusters`, `cws_service_account_email`, `cluster_dev_id`, `cluster_test_id`, `cluster_prod_id`, `secure_source_manager_instance_git_http`, `secure_source_manager_repository_git_https`, `vpc_self_link`.

## Dependencies

- Local modules: None.
- Remote modules:
  - `github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v9.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0`
