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

# Workstations Blueprint (`workstations`)

## Overview

The `infra/blueprints/workstations` Terraform blueprint deploys and manages
Google Cloud Workstations and their supporting custom container image CI/CD
pipelines. It activates required project APIs, provisions VPC/subnet/Private
Service Access/Cloud NAT/firewall networking, binds project-level IAM roles for
workstation and admin users, optionally expands workstation configurations
across a matrix of Android branches and targets, and invokes the
`cicd_foundation` module (`v8.0.0`, mirrored locally at
[`../../modules/cicd_foundation`](../../modules/cicd_foundation/EGM.md)) to
provision workstation clusters, configurations, instances, Artifact Registry
repositories, Secure Source Manager (SSM) repositories, Cloud Build triggers,
and Cloud Scheduler jobs.

## Interface

- Inputs (Project and Regions): `project_id` (required), `enable_apis`
  (default `true`), `artifact_registry_region`, `cloud_build_region`,
  `scheduler_default_region`, `secret_manager_region`,
  `secure_source_manager_region`, and `vpc_region` (all defaulting to
  `"us-central1"`).
- Inputs (Networking): `create_vpc` (default `true`), `vpc_name` (default
  `"workstations"`), `subnet_name` (default `"primary"`), `subnet_cidr`
  (default `"10.8.0.0/16"`), `psa_cidr` (default `"10.60.0.0/16"`), and
  `create_cloud_nat` (default `null`).
- Inputs (Source Control and CI/CD): `github_owner`, `github_repo`,
  `git_branches_regexp_trigger` (default `"^main$"`), `git_branch_trigger`
  (default `"main"`), `secure_source_manager_always_create` (default `false`),
  `secure_source_manager_deletion_policy` (default `"PREVENT"`),
  `secure_source_manager_instance_id`, `secure_source_manager_instance_name`
  (default `"cicd-foundation"`), `secure_source_manager_repo_name` (default
  `"cicd-foundation"`), `secure_source_manager_repo_git_url_to_clone` (default
  `"https://github.com/GoogleCloudPlatform/cicd-foundation.git"`),
  `build_machine_type_default` (default `"UNSPECIFIED"`),
  `build_source_retention_days` (default `7`), `build_timeout_default_seconds`
  (default `7200`), and `apps`.
- Inputs (Cloud Workstations, Android Matrix, and Agentic Review):
  `cws_clusters`, `cws_configs`, `cws_custom_images`,
  `boot_disk_size_gb_default` (default `100`),
  `disable_public_ip_addresses_default` (default `false`),
  `enable_nested_virtualization_default` (default `true`),
  `idle_timeout_seconds_default` (default `3600`), `machine_type_default`
  (default `"n1-standard-96"`), `pool_size_default` (default `0`),
  `persistent_disk_reclaim_policy_default` (default `"RETAIN"`),
  `persistent_disk_fs_type_default` (default `"ext4"`),
  `persistent_disk_type_default` (default `"pd-balanced"`),
  `android_branches`, `android_targets`, `default_agentic_instructions`,
  `default_agentic_location`, `default_agentic_model`,
  `default_agentic_personas`, and `default_agentic_prompt`.
- Inputs (IAM): `workstation_users` (list of developer emails), `admin_users`
  (list of admin emails), `admin_roles` (roles for admin users), and
  `user_roles` (roles for union of workstation and admin users).
- Outputs (`outputs.tf`): `secure_source_manager_repository_git_html` and
  `secure_source_manager_repository_git_https` (exposed from
  `module.cicd_foundation` when `length(var.cws_custom_images) > 0`, otherwise
  `null`).
- Instantiated modules and resources: `data.google_project.project`
  (`main.tf`), `module.project_services`
  (`terraform-google-modules/project-factory/google//modules/project_services`,
  `v18.2.0`), `module.vpc` (`cloud-foundation-fabric//modules/net-vpc`,
  `v49.0.0`, with state migration block `moved { from = module.vpc, to =
module.vpc[0] }` in `moved.tf`), `module.fw`
  (`cloud-foundation-fabric//modules/net-vpc-firewall`, `v49.0.0`),
  `module.nat` (`cloud-foundation-fabric//modules/net-cloudnat`, `v49.0.0`),
  `google_project_iam_member.admin_roles` and
  `google_project_iam_member.user_roles` (`iam.tf`), and
  `module.cicd_foundation`
  (`GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation`,
  `v8.0.0`).

## Invariants

- Terraform and provider versions (`terraform.tf`): Requires Terraform `>=
1.9.6` and `hashicorp/google` provider `>= 7.5.0`.
- Backend and impersonation configuration (`terraform.tf`): Configures a `gcs`
  remote state backend and `google` provider with service account
  impersonation (`impersonate_service_account`) and `user_project_override =
true`.
- Non-destructive API management (`main.tf`): `module.project_services`
  enforces `disable_services_on_destroy = false` so enabled Google Cloud APIs
  are preserved on destroy.
- Ordering dependencies (`main.tf`, `network.tf`, `workstations.tf`):
  `data.google_project.project` depends on `module.project_services`;
  `module.vpc` and `module.fw` depend on `data.google_project.project`;
  `module.cicd_foundation` depends on `module.vpc`,
  `google_project_iam_member.admin_roles`, and
  `google_project_iam_member.user_roles`.
- Conditional Cloud NAT invariant (`main.tf`): When `var.create_cloud_nat` is
  `null`, `local.deploy_nat` automatically enables Cloud NAT if
  `var.disable_public_ip_addresses_default` is `true` or any workstation
  configuration sets `disable_public_ip_addresses = true`.
- Workstation configuration and Android matrix transformation (`main.tf`): In
  `local.cws_configs_with_creators`, every configuration key resets
  `instances = null`, and the `"custom"` configuration key merges
  `var.workstation_users` and `var.admin_users` into `creators`. When both
  `var.android_branches` and `var.android_targets` are non-empty
  (`local.has_android_builds`), `local.cws_configs_product` generates the
  Cartesian product `<config_key>-<branch>-<target>` and truncates instance
  names using substring rules (`substr(i.name, 0, 12)` and 6/7-character
  branch/target segments).
- Resource retention defaults (`variables.tf`): Workstation persistent disks
  default to `RETAIN` (`persistent_disk_reclaim_policy_default`), and Secure
  Source Manager (SSM) defaults to `PREVENT`
  (`secure_source_manager_deletion_policy`).

## Side Effects

- Google Cloud API activation (`main.tf`): Enables
  `aiplatform.googleapis.com`, `cloudresourcemanager.googleapis.com`,
  `compute.googleapis.com`, `monitoring.googleapis.com`,
  `servicenetworking.googleapis.com`, and `serviceusage.googleapis.com` on
  `var.project_id`, plus downstream APIs in `module.cicd_foundation`.
- Networking and firewall provisioning (`network.tf`): Conditionally creates a
  VPC (`var.vpc_name`), regional subnet (`var.subnet_name` with CIDR
  `var.subnet_cidr`), and Private Service Access range (`var.psa_cidr`);
  provisions firewall rules from `firewall/rules` and `firewall/cidrs.yaml`;
  conditionally creates a Cloud Router (`<vpc_name>-router`) and Cloud NAT
  (`<vpc_name>-nat`).
- Project IAM bindings (`iam.tf`): Creates `google_project_iam_member`
  bindings granting `var.admin_roles` to `var.admin_users` and
  `var.user_roles` to the union of `var.workstation_users` and
  `var.admin_users`.
- Cloud Workstations and CI/CD infrastructure (`workstations.tf`): Via
  `module.cicd_foundation`, provisions Cloud Workstations clusters,
  workstation configurations, workstation instances, Artifact Registry
  repositories, workstation service account IAM bindings, and (when custom
  images are configured) Secure Source Manager (SSM) instance/repository,
  initial repository clone Cloud Build trigger, push-triggered Cloud Build
  triggers (`skaffold.yaml`), and periodic Cloud Scheduler image rebuild jobs.
