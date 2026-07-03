# Copyright 2024-2026 Google LLC
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

module "cicd_foundation" {
  source = "github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v5.0.1"

  project_id  = data.google_project.project.project_id
  enable_apis = var.enable_apis
  # go/keep-sorted start
  artifact_registry_region                    = var.artifact_registry_region
  boot_disk_size_gb_default                   = var.boot_disk_size_gb_default
  build_machine_type_default                  = var.build_machine_type_default
  build_timeout_default_seconds               = var.build_timeout_default_seconds
  cloud_build_region                          = var.cloud_build_region
  cws_clusters                                = var.cws_clusters
  cws_configs                                 = local.cws_configs_product
  cws_custom_images                           = var.cws_custom_images
  disable_public_ip_addresses_default         = var.disable_public_ip_addresses_default
  enable_nested_virtualization_default        = var.enable_nested_virtualization_default
  git_branch_trigger                          = var.git_branch_trigger
  git_branches_regexp_trigger                 = var.git_branches_regexp_trigger
  github_owner                                = var.github_owner
  github_repo                                 = var.github_repo
  idle_timeout_seconds_default                = var.idle_timeout_seconds_default
  machine_type_default                        = var.machine_type_default
  persistent_disk_fs_type_default             = var.persistent_disk_fs_type_default
  persistent_disk_reclaim_policy_default      = var.persistent_disk_reclaim_policy_default
  persistent_disk_type_default                = var.persistent_disk_type_default
  pool_size_default                           = var.pool_size_default
  scheduler_default_region                    = var.scheduler_default_region
  secret_manager_region                       = var.secret_manager_region
  secure_source_manager_always_create         = var.secure_source_manager_always_create
  secure_source_manager_deletion_policy       = var.secure_source_manager_deletion_policy
  secure_source_manager_instance_id           = var.secure_source_manager_instance_id
  secure_source_manager_instance_name         = var.secure_source_manager_instance_name
  secure_source_manager_region                = var.secure_source_manager_region
  secure_source_manager_repo_git_url_to_clone = var.secure_source_manager_repo_git_url_to_clone
  secure_source_manager_repo_name             = var.secure_source_manager_repo_name
  # go/keep-sorted end

  depends_on = [
    module.vpc,
    google_project_iam_member.admin_roles,
    google_project_iam_member.user_roles,
  ]
}
