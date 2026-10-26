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

# CI/CD Foundation Module (`cicd_foundation`)

## Overview

The `cicd_foundation` Terraform module (`v8-0-0`) establishes an end-to-end
CI/CD and managed development environment foundation on Google Cloud by
orchestrating the [`cicd_pipelines`](../cicd_pipelines/EGM.md) and
[`cicd_workstations`](../cicd_workstations/EGM.md) modules. It unifies
application delivery pipelines (`var.apps` for Cloud Run and GKE) with custom
Cloud Workstation image build pipelines (`var.cws_custom_images`, mapped to
runtime `"workstations"`), and hydrates Cloud Workstation configurations
(`var.cws_configs`) so they automatically reference custom container images
built and stored in Artifact Registry by the CI/CD pipeline.

## Interface

- `project_id` (string, required): Target Google Cloud project ID.
- Application and stage inputs: `apps` (map of application objects with
  `build`, `runtime`, `stages`, source repository configuration
  `github`/`ssm`/`git_repo`, and `agents`), `apps_directory` (default
  `"apps"`), `runtimes` (default `["cloudrun", "gke", "workstations"]`), and
  `stages` (map of stage configurations for `dev`, `test`, `prod` with
  `cloud_run_region`, `gke_cluster`, `project_id`, `peered_network`,
  `require_approval`, `canary_percentages`, `canary_verify`, and Binary
  Authorization modes).
- Cloud Workstations inputs: `cws_clusters` (map of cluster definitions),
  `cws_configs` (map of workstation configurations supporting
  `custom_image_names`, `instances`, `boost_configs`, `accelerators`,
  disk/machine settings, and `shielded_instance_config`), `cws_custom_images`
  (map of custom workstation image build configurations and Cloud Scheduler
  `workstation_config` schedules), and workstation defaults
  (`machine_type_default`, `boot_disk_size_gb_default`,
  `idle_timeout_seconds_default`, `pool_size_default`, persistent disk
  defaults, `cws_service_account_name`, `cws_scopes`, and
  `cws_image_build_runner_role_*`).
- Source control, build, and security inputs: GitHub (`github_owner`,
  `github_repo`, `git_branches_regexp_trigger`) and Secure Source Manager
  (SSM) settings (`secure_source_manager_*`, `git_branch_trigger`), Artifact
  Registry settings (`artifact_registry_id`, `artifact_registry_name`,
  `artifact_registry_region`, `artifact_registry_readers`), Cloud Build and
  worker pool settings (`cloud_build_*`, `build_*`, builder image tags
  `docker_image_tag`, `gcloud_image_tag`, `skaffold_image_tag`), Binary
  Authorization/Kritis/KMS settings (`binary_authorization_always_create`,
  `kritis_*`, `kms_*`, `vulnz_attestor_name`), and agentic review defaults
  (`default_agentic_*`).
- Modules and resources instantiated:
  `module.project_services_cloud_resourcemanager` and
  `module.project_services`
  (`terraform-google-modules/project-factory/google//modules/project_services`
  `v18.1.0`), `module.cicd_pipelines`
  ([`../cicd_pipelines`](../cicd_pipelines/EGM.md), conditional on
  `length(local.all_apps) > 0`), `module.workstations`
  ([`../cicd_workstations`](../cicd_workstations/EGM.md)), and
  `resource.google_artifact_registry_repository_iam_member.workstation_artifactregistry_reader`.
- Outputs: `cloud_build_trigger_github_connection_needed`,
  `cloud_build_trigger_ids`, `cloud_build_trigger_trigger_ids`,
  `cws_clusters`, `cws_service_account_email`,
  `secure_source_manager_instance_git_http`,
  `secure_source_manager_instance_git_ssh`,
  `secure_source_manager_instance_html`,
  `secure_source_manager_repository_git_html`, and
  `secure_source_manager_repository_git_https`.

## Invariants

- Application source exclusivity (`var.apps` validation): Each entry in
  `var.apps` may specify at most one source repository block among `github`,
  `ssm`, or `git_repo` (`sum(...) <= 1`).
- Canary stage configuration (`var.stages` validations): `canary_percentages`
  can only be set for a stage when `gke_cluster` is also set on that stage,
  and `canary_percentages` and `canary_verify` must either both be specified
  or both be omitted.
- SSM CA pool exclusivity (`var.secure_source_manager_create_ca_pool`
  validation): `secure_source_manager_create_ca_pool` cannot be set to `true`
  when `secure_source_manager_ca_pool` is non-null.
- Pipeline instantiation and custom image dependency: `module.cicd_pipelines`
  is only instantiated when `length(local.all_apps) > 0` (where
  `local.all_apps = merge(local.cws_apps, var.apps)`). If any entry in
  `var.cws_configs` defines non-empty `custom_image_names`,
  `local.cws_configs_hydrated` references
  `module.cicd_pipelines[0].artifact_registry_repository_uri`, requiring
  `local.all_apps` to be non-empty.
- Workstation configuration hydration and instance naming (`workstations.tf`):
  Each `var.cws_configs` entry with non-empty `custom_image_names` is fanned
  out into one hydrated configuration per custom image keyed as
  `"${config_key}-${custom_image_name}"` with `image =
"${module.cicd_pipelines[0].artifact_registry_repository_uri}/${custom_image_name}:latest"`,
  `custom_image_names = []`, and instance names truncated and hashed as
  `"${substr(instance.name, 0, 28)}-${substr(custom_image_name, 0,
27)}-${substr(sha256("${instance.name}-${custom_image_name}"), 0, 4)}"` to
  satisfy Google Cloud naming length and uniqueness constraints.
- Label normalization (`main.tf`): `local.common_labels` merges `var.labels`
  with `local.default_labels` (where default module metadata labels take
  precedence on key collision) and converts all keys and values to lowercase.
- API enablement ordering (`main.tf`): `cloudresourcemanager.googleapis.com`
  is enabled prior to `artifactregistry.googleapis.com` (and conditional
  `privateca.googleapis.com`), which completes before
  `data.google_project.project` is evaluated.

## Side Effects

- Google Cloud API enablement: Enables `cloudresourcemanager.googleapis.com`,
  `artifactregistry.googleapis.com`, and conditionally
  `privateca.googleapis.com` (when `secure_source_manager_create_ca_pool &&
secure_source_manager_ca_pool == null`) on `var.project_id` when
  `var.enable_apis` is `true`, with `disable_services_on_destroy = false`.
- Artifact Registry IAM binding: Creates
  `google_artifact_registry_repository_iam_member.workstation_artifactregistry_reader`
  (when `length(var.cws_custom_images) > 0`) granting
  `roles/artifactregistry.reader` on the CI/CD Artifact Registry repository to
  `serviceAccount:${module.workstations.cws_service_account_email}`.
- CI/CD pipeline provisioning
  ([`../cicd_pipelines`](../cicd_pipelines/EGM.md)): When
  `length(local.all_apps) > 0`, provisions Artifact Registry repositories,
  Cloud Build triggers, worker pools, service accounts, and API keys, Cloud
  Storage staging buckets, Cloud Deploy pipelines and targets, Cloud Scheduler
  jobs for workstation image rebuilds, Binary Authorization attestors/KMS
  keys/Container Analysis notes, and Secure Source Manager
  instances/repositories/CA pools.
- Cloud Workstations provisioning
  ([`../cicd_workstations`](../cicd_workstations/EGM.md)): Provisions Cloud
  Workstation clusters, workstation configurations, workstation instances,
  workstation service accounts, and associated IAM bindings.
