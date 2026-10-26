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

# Simplified Team Module (`team`)

## Overview

The `infra/simplified/team` Terraform module provisions per-team (per-developer)
resources within an existing Google Cloud project to support an isolated
development and continuous integration/continuous delivery workflow. Given a
`team` prefix and `user_identity`, it configures a dedicated Cloud Workstation
instance, a Secure Source Manager (SSM) repository, a team-scoped Docker
Artifact Registry repository, and per-application Cloud Build triggers, Cloud
Deploy delivery pipelines, and Cloud Deploy release promotion automations.

## Interface

- `main.tf`: Defines `module "project"`
  (`github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.0.0`)
  referencing an existing project (`project_create = false`) to enable
  `var.project_services` and add an additive IAM binding
  (`roles/containeranalysis.occurrences.editor`) for the Cloud Build service
  account (`var.sa-cb-email`).
- `workstations.tf`: Defines `resource "google_workstations_workstation"
"cicd_foundation"`, `data "google_iam_policy" "workstations_user"`, and
  `resource "google_workstations_workstation_iam_policy" "policy"` (using
  `google-beta` provider) to provision a workstation with ID `var.team` under
  `var.ws_cluster_id` and `var.ws_config_id` and grant
  `roles/workstations.user` to `user:${var.user_identity}`.
- `source.tf`: Defines `resource "google_secure_source_manager_repository"
"repo"` (named `var.team` on instance `var.ssm_instance_name` in
  `var.ssm_region` with default branch `main`) and `resource
"google_secure_source_manager_repository_iam_binding" "repo_writer"`
  granting `roles/securesourcemanager.repoWriter` to
  `user:${var.user_identity}`.
- `build.tf`: Defines `module "docker_artifact_registry"`
  (`github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/artifact-registry?ref=v34.0.0`)
  creating a standard Docker repository named `${var.team}-${var.registry_id}`
  in `var.region` with `roles/artifactregistry.reader` and
  `roles/artifactregistry.writer` bindings.
- `apps.tf`: Defines `for_each = var.apps` resources: `resource
"google_cloudbuild_trigger" "continuous-integration"` (using `google-beta`),
  `resource "google_clouddeploy_delivery_pipeline" "continuous-delivery"`, and
  `resource "google_clouddeploy_automation" "promote-release"`, each named
  `${var.team}-${each.key}`.
- `variables.tf`: Declares 36 input variables covering identity/scoping
  (`user_identity`, `team`, `project_id`, `region`, `project_services`),
  source control (`ssm_instance_name`, `ssm_region`, `webhook_trigger_secret`,
  `github_owner`, `github_repo`, `git_branch_trigger`,
  `git_branch_trigger_regexp`), workstation attachment (`ws_cluster_id`,
  `ws_config_id`), build/signing tooling (`skaffold_quiet`, `skaffold_output`,
  `skaffold_image_tag`, `docker_image_tag`, `gcloud_image_tag`, `policy_file`,
  `kritis_signer_image`, `kritis_note`, `kms_key_name`, `kms_digest_alg`,
  `registry_id`, `build_machine_type_default`, `build_timeout_default`),
  application/pipeline definitions (`apps`, `stages`, `runtimes`), and
  pre-existing service accounts (`sa-ws-email`, `sa-cb-id`, `sa-cb-email`,
  `sa-cluster-prod-email`, `sa-cluster-test-email`, `sa-cluster-dev-email`).
- `outputs.tf`: Contains license header comments and declares no Terraform
  outputs.

## Invariants

- Pre-existing shared infrastructure dependency: The Google Cloud project
  (`var.project_id`, with `project_create = false`), Cloud Workstations
  cluster (`var.ws_cluster_id`) and configuration (`var.ws_config_id`), Secure
  Source Manager (SSM) instance (`var.ssm_instance_name`), KMS key
  (`var.kms_key_name`), Kritis note (`var.kritis_note`), Cloud Deploy targets
  (`cluster-${stage}` or `run-${stage}`), and service accounts (`sa-ws-email`,
  `sa-cb-id`, `sa-cb-email`, `sa-cluster-prod-email`, `sa-cluster-test-email`,
  `sa-cluster-dev-email`) provisioned by [`../hub`](../hub/EGM.md) must exist
  before applying this module.
- Team naming convention: All team-scoped resources use `var.team` as either
  the exact identifier (workstation ID, SSM `repository_id`, Kubernetes
  `_NAMESPACE` substitution) or resource prefix
  (`${var.team}-${var.registry_id}` for Artifact Registry,
  `${var.team}-${each.key}` for Cloud Build triggers, Cloud Deploy pipelines,
  and Cloud Deploy automations).
- Dual source trigger mode: In
  `google_cloudbuild_trigger.continuous-integration`, if both
  `var.github_owner` and `var.github_repo` are non-empty strings, a `github`
  push trigger (`branch = var.git_branch_trigger_regexp`) is configured;
  otherwise, `webhook_config` (using `var.webhook_trigger_secret`) and
  `source_to_build` (pointing to
  `google_secure_source_manager_repository.repo.name` at
  `refs/heads/${var.git_branch_trigger}` with `repo_type = "UNKNOWN"`) are
  configured.
- Repository path structure: Cloud Build triggers watch `included_files =
["apps/${each.key}/**"]`, execute Skaffold/Docker/gcloud steps in working
  directory `apps/$${_APP_NAME}`, and reference `var.policy_file` (default
  `./tools/kritis/vulnz-signing-policy.yaml`) from the repository root.
- Pipeline stage and target mapping:
  `google_clouddeploy_delivery_pipeline.continuous-delivery` iterates over
  `var.stages` in a `serial_pipeline`, mapping each stage to profile
  `[stages.value]` and `target_id = each.value.runtime == "gke" ?
"cluster-${stages.value}" : "run-${stages.value}"`. Each stage requires
  `each.value.stages[stages.value]` to be indexable for `deploy_parameters`.
- Canary strategy constraint: A canary deployment strategy (`percentages =
[10, 25, 50]`, `verify = false`, using Kubernetes `gateway_service_mesh`
  with `deployment`, `http_route`, and `service` all set to `each.key` and
  `route_update_wait_time = "120s"`) is enabled only when `stages.value ==
"prod" && each.value.runtime == "gke"`.
- Non-blocking image digest and signing steps: In the Cloud Build pipeline
  (`build` -> `fetchImageDigest` -> `vulnsign` -> `createRelease`), both
  `fetchImageDigest` and `vulnsign` set `allow_failure = true`, and builds
  require `requested_verify_option = "VERIFIED"` and `logging =
"CLOUD_LOGGING_ONLY"`.

## Side Effects

- Enables project APIs specified in `var.project_services` (defaults to
  `compute`, `container`, `cloudkms`, `monitoring`, `binaryauthorization`,
  `containersecurity` `.googleapis.com`) and grants
  `roles/containeranalysis.occurrences.editor` on `var.project_id` to
  `serviceAccount:${var.sa-cb-email}`.
- Provisions a Cloud Workstation
  (`google_workstations_workstation.cicd_foundation`) named `var.team` and
  sets an authoritative workstation IAM policy
  (`google_workstations_workstation_iam_policy.policy`) granting
  `roles/workstations.user` to `user:${var.user_identity}`.
- Provisions a Secure Source Manager (SSM) repository
  (`google_secure_source_manager_repository.repo`) with ID `var.team` and
  default branch `main`, and binds `roles/securesourcemanager.repoWriter` for
  `user:${var.user_identity}`.
- Provisions a standard Docker Artifact Registry repository
  (`${var.team}-${var.registry_id}`) in `var.region` granting
  `roles/artifactregistry.reader` to Cloud Build, Cloud Workstations,
  DEV/TEST/PROD GKE cluster service accounts, and `user:${var.user_identity}`,
  plus `roles/artifactregistry.writer` to Cloud Build service account and
  `user:${var.user_identity}`.
- Provisions one Cloud Build trigger
  (`google_cloudbuild_trigger.continuous-integration`), one Cloud Deploy
  delivery pipeline
  (`google_clouddeploy_delivery_pipeline.continuous-delivery`), and one active
  (`suspended = false`) Cloud Deploy automation
  (`google_clouddeploy_automation.promote-release` targeting `*` with
  `promote_release_rule`) per application entry in `var.apps`.
