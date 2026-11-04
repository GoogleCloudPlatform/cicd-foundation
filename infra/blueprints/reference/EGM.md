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

The `infra/blueprints/reference` Terraform blueprint implements an enterprise multi-environment (`DEV`, `TEST`, `PROD`) software supply chain and runtime platform on Google Cloud. It establishes a hub-and-spoke organization hierarchy with a centralized Hub connected to isolated Production, Testing, and Development spoke environments (each segmented into Shared VPC host, supplychain build/deploy, and GKE Autopilot/Cloud Run service projects). The supply chain and developer environments are unified by instantiating the `cicd_foundation` module (`v9.0.0`, mirrored locally at [`../../modules/cicd_foundation`](../../modules/cicd_foundation/EGM.md)).

## Interface

- Inputs (Organization, Folders, and Projects): `org_id`, `folders_create`, `folder_{hub,prod,test,dev}_id`, `projects_create`, `project_hub_{host,supplychain}`, `project_{prod,test,dev}_{host,supplychain,service}`, and `project_*_services`.
- Inputs (Networking): `region` (default `"us-central1"`), `zone` (default `"us-central1-a"`), `vpc_create`, `vpc_subnet_name`, `nat_name`, `vpc-hub_primary_cidr`, `vpc-hub_psa_cidr`, `vpc-{prod,test,dev}_psa_cidr`, `vpc-{prod,test,dev}-build_primary_cidr`, `vpc-{prod,test,dev}-build_psa_cidr`, and `cluster-{prod,test,dev}_network_config`.
- Inputs (CI/CD, Workstations, Security, Runtime): `apps`, `runtimes`, `developers`, `github_owner`, `github_repo`, `git_branch_trigger`, `git_branch_trigger_regexp`, `kritis_signer_image`, `secure_source_manager_always_create`, `ssm_branch_rule`, `cb_pool_name`, `cb_pool_machine_type`, `cb_pool_disk_size_gb`, `prod_canary_percentages`, `prod_canary_verify`, `canary_route_update_wait_time_seconds`, `cws_custom_images`, `machine_type_default`, `boot_disk_size_gb_default`, `ws_pd_disk_size_gb`, `idle_timeout_seconds_default`.
- Outputs: `cloud_build_trigger_ids`, `cloud_build_trigger_trigger_ids`, `cws_clusters`, `cws_service_account_email`, `cluster_dev_id`, `cluster_test_id`, `cluster_prod_id`, `secure_source_manager_instance_git_http`, `secure_source_manager_repository_git_https`, `vpc_hub_self_link`, `vpc_dev_self_link`, `vpc_test_self_link`, `vpc_prod_self_link`.

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
