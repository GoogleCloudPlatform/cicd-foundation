# Copyright 2023-2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "cicd_pipelines" {
  count = length(local.all_apps) > 0 ? 1 : 0

  source = "./cicd_pipelines"

  project_id  = data.google_project.project.project_id
  enable_apis = var.enable_apis
  namespace   = var.namespace
  # go/keep-sorted start
  apps                                        = local.all_apps
  apps_directory                              = var.apps_directory
  artifact_registry_id                        = var.artifact_registry_id
  artifact_registry_name                      = var.artifact_registry_name
  artifact_registry_readers                   = var.artifact_registry_readers
  artifact_registry_region                    = var.artifact_registry_region
  binary_authorization_always_create          = var.binary_authorization_always_create
  build_machine_type_default                  = var.build_machine_type_default
  build_source_retention_days                 = var.build_source_retention_days
  build_timeout_default_seconds               = var.build_timeout_default_seconds
  canary_route_update_wait_time_seconds       = var.canary_route_update_wait_time_seconds
  canary_verify                               = var.canary_verify
  cloud_build_api_key_display_name            = var.cloud_build_api_key_display_name
  cloud_build_api_key_name                    = var.cloud_build_api_key_name
  cloud_build_peered_network                  = var.cloud_build_peered_network
  cloud_build_pool_disk_size_gb               = var.cloud_build_pool_disk_size_gb
  cloud_build_pool_machine_type               = var.cloud_build_pool_machine_type
  cloud_build_pool_name                       = var.cloud_build_pool_name
  cloud_build_region                          = var.cloud_build_region
  cloud_build_service_account_name            = var.cloud_build_service_account_name
  cws_image_build_runner_role_create          = var.cws_image_build_runner_role_create
  cws_image_build_runner_role_id              = var.cws_image_build_runner_role_id
  cws_image_build_runner_role_title           = var.cws_image_build_runner_role_title
  default_agentic_instructions                = var.default_agentic_instructions
  default_agentic_location                    = var.default_agentic_location
  default_agentic_model                       = var.default_agentic_model
  default_agentic_personas                    = var.default_agentic_personas
  default_agentic_prompt                      = var.default_agentic_prompt
  default_ci_schedule                         = var.default_ci_schedule
  deploy_region                               = var.deploy_region
  docker_image_tag                            = var.docker_image_tag
  gcloud_image_tag                            = var.gcloud_image_tag
  git_branch_trigger                          = var.git_branch_trigger
  git_branches_regexp_trigger                 = var.git_branches_regexp_trigger
  github_owner                                = var.github_owner
  github_repo                                 = var.github_repo
  kms_digest_alg                              = var.kms_digest_alg
  kms_key_destroy_scheduled_duration_days     = var.kms_key_destroy_scheduled_duration_days
  kms_key_name                                = var.kms_key_name
  kms_keyring_location                        = var.kms_keyring_location
  kms_keyring_name                            = var.kms_keyring_name
  kms_signing_alg                             = var.kms_signing_alg
  kritis_policy_default                       = var.kritis_policy_default
  kritis_policy_file                          = var.kritis_policy_file
  kritis_signer_image                         = var.kritis_signer_image
  labels                                      = var.labels
  runtimes                                    = var.runtimes
  scheduler_default_region                    = var.scheduler_default_region
  secret_manager_region                       = var.secret_manager_region
  secure_source_manager_always_create         = var.secure_source_manager_always_create
  secure_source_manager_ca_common_name        = var.secure_source_manager_ca_common_name
  secure_source_manager_ca_key_algorithm      = var.secure_source_manager_ca_key_algorithm
  secure_source_manager_ca_lifetime_seconds   = var.secure_source_manager_ca_lifetime_seconds
  secure_source_manager_ca_organization       = var.secure_source_manager_ca_organization
  secure_source_manager_ca_pool               = var.secure_source_manager_ca_pool
  secure_source_manager_create_ca_pool        = var.secure_source_manager_create_ca_pool
  secure_source_manager_deletion_policy       = var.secure_source_manager_deletion_policy
  secure_source_manager_instance_id           = var.secure_source_manager_instance_id
  secure_source_manager_instance_name         = var.secure_source_manager_instance_name
  secure_source_manager_region                = var.secure_source_manager_region
  secure_source_manager_repo_git_url_to_clone = var.secure_source_manager_repo_git_url_to_clone
  secure_source_manager_repo_name             = var.secure_source_manager_repo_name
  service_account_cloud_deploy_name           = var.service_account_cloud_deploy_name
  skaffold_image_tag                          = var.skaffold_image_tag
  skaffold_output                             = var.skaffold_output
  skaffold_quiet                              = var.skaffold_quiet
  ssm_branch_rule                             = var.ssm_branch_rule
  ssm_project_id                              = var.ssm_project_id
  stages                                      = var.stages
  vulnz_attestor_name                         = var.vulnz_attestor_name
  # go/keep-sorted end
}
