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

## Overview

The `infra/blueprints/reference` Terraform blueprint implements a generalized enterprise hub-and-spoke multi-environment software supply chain and runtime platform on Google Cloud. It establishes a centralized Hub (`folder_hub`, `project_hub_host`, `project_hub_supplychain`) connected to an arbitrary map of spoke environments (`var.environments`, e.g., `dev`, `test`, `prod`), each segmented into Shared VPC host, supplychain worker-pool, and GKE Autopilot/Cloud Run service projects. Supply chain pipelines and Cloud Workstations are provisioned by instantiating `cicd_foundation` (`v9.0.0`, mirrored locally at [`../../modules/cicd_foundation`](../../modules/cicd_foundation/EGM.md)).

## Interface

- Inputs (Organization, Hub, and Spoke Environments): `org_id`, `folders_create`, `folder_hub_id`, `projects_create`, `project_hub_{host,supplychain}`, `project_hub_{host,supplychain}_services`, `spoke_{host,supplychain,service}_services`, and `environments` (map of spoke environment objects configuring `order`, `folder_display_name`, `folder_id`, `projects`, `network`, cluster endpoint/Binary Authorization flags, approval, and canary settings).
- Inputs (Networking): `region` (default `"us-central1"`), `zone` (default `"us-central1-a"`), `vpc_create`, `vpc_subnet_name`, `vpc_hub_primary_cidr`, `vpc_hub_psa_cidr`, plus per-environment CIDRs under `environments[*].network`.
- Inputs (CI/CD, Workstations, Security, Runtime): `apps`, `runtimes`, `developers`, `github_owner`, `github_repo`, `git_branch_trigger`, `git_branch_trigger_regexp`, `kritis_signer_image`, `secure_source_manager_always_create`, `ssm_branch_rule`, `cb_pool_name`, `cb_pool_machine_type`, `cb_pool_disk_size_gb`, `canary_route_update_wait_time_seconds`, `cws_custom_images`, `machine_type_default`, `boot_disk_size_gb_default`, `ws_pd_disk_size_gb`, `idle_timeout_seconds_default`.
- Outputs: `cloud_build_trigger_github_connection_needed`, `cloud_build_trigger_ids`, `cloud_build_trigger_trigger_ids`, `cluster_ids`, `cws_clusters`, `cws_service_account_email`, `secure_source_manager_instance_git_http`, `secure_source_manager_instance_git_ssh`, `secure_source_manager_instance_html`, `secure_source_manager_repository_git_html`, `secure_source_manager_repository_git_https`, `vpc_hub_self_link`, `vpc_spoke_self_links`.
- Direct resources: `google_compute_ha_vpn_gateway.build_to_spoke`, `google_compute_ha_vpn_gateway.spoke_to_build`, and `google_compute_network_peering_routes_config.cluster_peering_routes` (for each key in `var.environments`).

## Dependencies

- Local modules: None.
- Remote modules:
  - `github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v9.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/organization?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpn-ha?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0`
  - `github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0`
