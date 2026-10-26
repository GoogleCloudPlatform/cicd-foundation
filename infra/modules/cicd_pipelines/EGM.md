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

# CI/CD Pipelines Module (`cicd_pipelines`)

## Overview

The `cicd_pipelines` Terraform module (`v8-0-0`) provisions an end-to-end Google
Cloud-native CI/CD environment (`main.tf`, `build.tf`, `deploy.tf`, `source.tf`,
`registry.tf`, `binauth.tf`, `workstations.tf`, `variables.tf`, `outputs.tf`).
It configures source control integration (Secure Source Manager (SSM), GitHub,
or generic Git repository webhooks), Docker Artifact Registry storage, Cloud
Build CI pipelines (with recursive Skaffold dependency resolution, optional
pre-build multi-persona Gemini agentic code reviews, Kritis vulnerability
scanning/signing, and a bootstrapped `build-runner` image), Cloud Deploy
multi-stage serial delivery pipelines and targets for Cloud Run and GKE (with
optional approvals and GKE Service Mesh canary strategies), Binary Authorization
policies/attestors backed by Cloud Key Management Service (KMS) and Container
Analysis notes, and Cloud Scheduler jobs for periodic rebuilds (such as Cloud
Workstations base image patching).

## Interface

- Input Variables (`variables.tf`):
  - Project and Naming: `project_id` (required), `namespace`, `labels`,
    `enable_apis`.
  - Region Configuration: `artifact_registry_region`, `cloud_build_region`,
    `deploy_region`, `kms_keyring_location`, `scheduler_default_region`,
    `secret_manager_region`, `secure_source_manager_region`.
  - Applications and Stages: `apps` map configuring `build`, `runtime`,
    `stages`, `git_repo`, `github`, `ssm`, `workstation_config`, and
    `agents`; `apps_directory`; `runtimes` defaulting to `["cloudrun",
"gke", "workstations"]`; `stages` map configuring `cloud_run_region`,
    `gke_cluster`, `project_id`, `peered_network`, `require_approval`,
    `canary_percentages`, `canary_verify`,
    `binary_authorization_evaluation_mode`, and
    `binary_authorization_enforcement_mode`.
  - Source Control: `git_branch_trigger`, `git_branches_regexp_trigger`,
    `github_owner`, `github_repo`, `secure_source_manager_always_create`,
    `secure_source_manager_instance_id`,
    `secure_source_manager_instance_name`,
    `secure_source_manager_repo_name`,
    `secure_source_manager_repo_git_url_to_clone`,
    `secure_source_manager_deletion_policy`,
    `secure_source_manager_ca_pool`, `secure_source_manager_create_ca_pool`,
    `secure_source_manager_ca_common_name`,
    `secure_source_manager_ca_organization`,
    `secure_source_manager_ca_key_algorithm`,
    `secure_source_manager_ca_lifetime_seconds`.
  - Cloud Build: `build_machine_type_default`,
    `build_timeout_default_seconds`, `build_source_retention_days`,
    `cloud_build_api_key_name`, `cloud_build_api_key_display_name`,
    `cloud_build_peered_network`, `cloud_build_pool_name`,
    `cloud_build_pool_machine_type`, `cloud_build_pool_disk_size_gb`,
    `cloud_build_service_account_name`, `docker_image_tag`,
    `gcloud_image_tag`, `skaffold_image_tag`, `skaffold_output`,
    `skaffold_quiet`.
  - Binary Authorization and KMS: `binary_authorization_always_create`,
    `kritis_signer_image`, `kritis_policy_file`, `kritis_policy_default`,
    `vulnz_attestor_name`, `kms_keyring_name`, `kms_key_name`,
    `kms_signing_alg`, `kms_digest_alg`,
    `kms_key_destroy_scheduled_duration_days`.
  - Artifact Registry and Cloud Deploy: `artifact_registry_id`,
    `artifact_registry_name`, `artifact_registry_readers`,
    `service_account_cloud_deploy_name`,
    `canary_route_update_wait_time_seconds`, `canary_verify`.
  - Cloud Workstations and Agentic Review: `default_ci_schedule`,
    `cws_image_build_runner_role_create`, `cws_image_build_runner_role_id`,
    `cws_image_build_runner_role_title`, `default_agentic_model`,
    `default_agentic_location`, `default_agentic_personas`,
    `default_agentic_instructions`, `default_agentic_prompt`.
- Outputs (`outputs.tf`):
  - Secret Manager: `webhook_trigger_secret_id`,
    `webhook_trigger_secret_name`.
  - Secure Source Manager: `secure_source_manager_instance_id`,
    `secure_source_manager_instance_html`,
    `secure_source_manager_instance_git_http`,
    `secure_source_manager_instance_git_ssh`,
    `secure_source_manager_repository_id`,
    `secure_source_manager_repository_name`,
    `secure_source_manager_repository_git_html`,
    `secure_source_manager_repository_git_https`.
  - Cloud Build: `cloud_build_api_key` (sensitive),
    `cloud_build_service_account_email`, `cloud_build_service_account_id`,
    `cloud_build_trigger_github_connection_needed`,
    `cloud_build_trigger_id`, `cloud_build_trigger_trigger_id`,
    `cloud_build_worker_pool_ids`.
  - Binary Authorization, Artifact Registry, and Cloud Workstations:
    `binary_authorization_policy_id`, `artifact_registry_repository`,
    `artifact_registry_repository_uri`,
    `cws_image_build_runner_service_account_email`,
    `cws_image_build_runner_service_account_id`.
- Key Modules and Data Sources: `module.project_services`
  (`terraform-google-modules/project-factory/google//modules/project_services`,
  `v18.2.0`), `module.docker_artifact_registry`
  (`cloud-foundation-fabric//modules/artifact-registry`, `v45.0.0`),
  `module.service_account_cloud_build`, `module.service_account_cloud_deploy`,
  and `module.cws_image_build_runner_service_account`
  (`cloud-foundation-fabric//modules/iam-service-account`, `v45.0.0`),
  `data.google_project.project`,
  `data.google_artifact_registry_repository.container_repository`,
  `data.external.skaffold_deps`,
  `data.google_kms_crypto_key_version.vulnz_attestor`,
  `data.google_project_iam_custom_role.cws_image_build_runner_data`, and
  `data.google_iam_policy.secret_accessor`.
- Child Subdirectories:
  - [`./scripts/EGM.md`](./scripts/EGM.md): Invokes
    `scripts/resolve_skaffold_deps.py` via `data.external.skaffold_deps` to
    compute transitive `included_files`; embeds `scripts/clone.sh.template`,
    `scripts/build.sh.template`, `scripts/fetch_image_digest.sh.template`,
    `scripts/vulnsign.sh.template`, and `scripts/create_release.sh.template`
    via `file()` into `google_cloudbuild_trigger.ci_pipeline` build steps;
    and executes `infra/modules/cicd_pipelines/scripts/agentic_runner.py`
    inside the `agentic-pre-build-review` step using
    `local.ci_runner_image`.

## Invariants

- Application runtime and source validation (`variables.tf`): Every app's
  `runtime` in `var.apps` must be `null` or contained in `var.runtimes`
  (`["cloudrun", "gke", "workstations"]`); each app may specify at most one
  repository source (`github`, `ssm`, or `git_repo`); and all stage keys
  referenced in an app's `stages` map must exist in `var.stages`.
- Stage canary and CA pool validation (`variables.tf`): In `var.stages`,
  `canary_percentages` can only be set if `gke_cluster` is also set on that
  stage, and `canary_percentages` and `canary_verify` must either both be set
  or both be omitted. `var.secure_source_manager_create_ca_pool` cannot be
  `true` when `var.secure_source_manager_ca_pool` is non-null.
- Trigger matrix and naming invariant (`main.tf`, `build.tf`): `local.ci_apps`
  pairs each app with `["github", "manual", "webhook"]`: GitHub-backed apps
  generate two triggers (`<prefix><app>-github` and `<prefix><app>-manual`
  where `manual` sets `source_to_build`), while SSM or `git_repo` apps
  generate a single webhook trigger (`<prefix><app>`).
- Cloud Build step ordering and conditional pipeline invariant (`build.tf`):
  Build steps in `local.ci_build_specs` execute sequentially via `wait_for`:
  optional `clone` (when using SSM or `git_repo` webhook) -> optional
  `agentic-pre-build-review` (when `agents["pre-build"]["review"].enabled` is
  true) -> `build` -> `fetchImageDigest` -> optional `vulnsign` (when
  `var.kritis_signer_image` is non-empty, with `allow_failure = true`) ->
  optional `createRelease` (only for apps in `local.cloud_deploy_apps` where
  `runtime` is `"cloudrun"` or `"gke"`).
- Secret Manager environment variable resolution (`main.tf`, `build.tf`): App
  `build.env` values prefixed with `sm://` are stripped from plain `env` and
  mapped into Cloud Build `secret_env` and `available_secrets.secret_manager`,
  resolving full `projects/...` resource paths, `<secret>/<version>` pairs in
  `local.build_project_id`, or `<secret>` defaulting to `versions/latest`.
- Binary Authorization and GKE cluster format invariant (`binauth.tf`):
  `local.use_binary_authorization` is true only when `var.kritis_signer_image`
  is non-empty, whereas Binary Authorization resources
  (`local.create_binary_authorization_resources`) are created when either
  `local.use_binary_authorization` or `var.binary_authorization_always_create`
  is true. Every stage's `gke_cluster` must match
  `projects/(?:[^/]+)/locations/([^/]+)/clusters/([^/]+)` so
  `local.cluster_details` can format `<location>.<cluster>` for
  `google_binary_authorization_policy.policy`.
- Cloud Scheduler pause and target invariant (`workstations.tf`):
  `google_cloud_scheduler_job.cws_image_rebuild` is created for all entries in
  `var.apps` (`local.scheduled_apps = var.apps`), defaulting `paused` to
  `false` only when `runtime == "workstations"` (and `true` otherwise unless
  overridden by `workstation_config.paused`), and targeting the `<app>-manual`
  trigger for GitHub sources or `<app>` trigger otherwise.
- Terraform lifecycle drift ignore rules (`build.tf`, `deploy.tf`,
  `source.tf`, `binauth.tf`): `google_cloudbuild_trigger.ci_pipeline` ignores
  changes to `included_files` and `source_to_build`;
  `google_clouddeploy_target`, `google_clouddeploy_delivery_pipeline`,
  `google_clouddeploy_automation`, `google_secure_source_manager_instance`,
  and `google_kms_crypto_key` ignore changes to `labels`.

## Side Effects

- Project APIs and API Keys (`main.tf`): Enables required Google Cloud APIs
  via `module.project_services` (`disable_services_on_destroy = false`),
  conditionally activating `clouddeploy.googleapis.com`,
  `cloudscheduler.googleapis.com`, `apikeys.googleapis.com`, and
  `securesourcemanager.googleapis.com`, and creates a
  `google_apikeys_key.cloud_build` restricted to `cloudbuild.googleapis.com`
  when SSM is active.
- Artifact Registry (`registry.tf`): Creates a Docker Artifact Registry
  repository (`module.docker_artifact_registry`) when
  `var.artifact_registry_id == null` and binds `roles/artifactregistry.reader`
  (for Cloud Build service account, Cloud Workstations image builder service
  account, and `var.artifact_registry_readers`) and
  `roles/artifactregistry.repoAdmin` (for Cloud Build service account).
- Cloud Build, Storage, and Local-Exec Bootstrap (`build.tf`): Creates the
  Cloud Build service account (`module.service_account_cloud_build`, granting
  `roles/aiplatform.user` when pre-build review agents are enabled), optional
  private worker pools (`google_cloudbuild_worker_pool.ci_pool` and per-stage
  `google_cloudbuild_worker_pool.pool` with `no_external_ip = true`), CI
  triggers (`google_cloudbuild_trigger.ci_pipeline`), a Cloud Storage
  staging/reports bucket (`google_storage_bucket.cloudbuild_source` with
  lifecycle auto-deletion after `var.build_source_retention_days` days and
  `roles/storage.objectAdmin` for the Cloud Build service account), and
  `null_resource.build_bootstrap_runner` which runs `gcloud builds submit` via
  `local-exec` to build and push
  `${local.artifact_registry_repository_uri}/build-runner:latest` whenever
  files in `apps/build-runner` change.
- Cloud Deploy (`deploy.tf`): When `local.cloud_deploy_apps` is non-empty,
  provisions per-stage Cloud Deploy execution service accounts
  (`module.service_account_cloud_deploy`), GKE targets
  (`google_clouddeploy_target.cluster`), Cloud Run targets
  (`google_clouddeploy_target.run`), serial delivery pipelines
  (`google_clouddeploy_delivery_pipeline.continuous_delivery`), and release
  promotion automation rules
  (`google_clouddeploy_automation.promote-release`).
- Secure Source Manager, Private CA, and Webhook Secrets (`source.tf`):
  Conditionally provisions an Enterprise Private CA pool and Root CA
  (`google_privateca_ca_pool.ssm_ca_pool`,
  `google_privateca_certificate_authority.ssm_root_ca`), an SSM instance and
  repository (`google_secure_source_manager_instance.cicd_foundation`,
  `google_secure_source_manager_repository.cicd_foundation`, plus
  `instanceAccessor` and `repoReader` IAM bindings), a webhook secret
  (`google_secret_manager_secret.webhook_trigger`,
  `random_id.webhook_secret_key`,
  `google_secret_manager_secret_version.webhook_trigger`, and
  `roles/secretmanager.secretAccessor` policy for the Cloud Build service
  agent), SSM push hooks
  (`google_secure_source_manager_hook.cicd_foundation`), and optional
  repository seeding resources (`google_service_account.git_clone_and_push`,
  `google_cloudbuild_trigger.git_clone_and_push`, and `local-exec`
  provisioners `null_resource.run_git_clone_and_push` and
  `null_resource.run_git_repo_trigger` executing `gcloud builds triggers
run`).
- Binary Authorization, KMS, and Container Analysis (`binauth.tf`):
  Conditionally provisions a Container Analysis attestation note
  (`google_container_analysis_note.vulnz_attestor` and IAM viewer binding for
  the Binary Authorization service agent), a KMS key ring and asymmetric
  signing key (`google_kms_key_ring.keyring`,
  `google_kms_crypto_key.vulnz_attestor_key`, and `roles/cloudkms.signer` for
  the Cloud Build service agent), a Binary Authorization attestor
  (`google_binary_authorization_attestor.vulnz_attestor`), and a project-wide
  Binary Authorization policy (`google_binary_authorization_policy.policy`).
- Cloud Workstations Scheduled Rebuilds (`workstations.tf`): When `var.apps`
  is non-empty, provisions or reads a custom IAM role
  (`google_project_iam_custom_role.cws_image_build_runner` with
  `cloudbuild.builds.create`), a dedicated runner service account
  (`module.cws_image_build_runner_service_account`), and per-app
  `google_cloud_scheduler_job.cws_image_rebuild` HTTP POST jobs that invoke
  the Cloud Build trigger `:run` endpoint.
