# Copyright 2026 Google LLC
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

locals {
  effective_github_owner = var.github_owner != null ? var.github_owner : (
    length([for _, v in var.developers : v.github_user if lookup(v, "github_user", "") != ""]) > 0 ?
    [for _, v in var.developers : v.github_user if lookup(v, "github_user", "") != ""][0] : null
  )

  effective_github_repo = var.github_repo != null ? var.github_repo : (
    length([for _, v in var.developers : v.github_repo if lookup(v, "github_repo", "") != ""]) > 0 ?
    [for _, v in var.developers : v.github_repo if lookup(v, "github_repo", "") != ""][0] : null
  )

  stages = {
    dev = {
      gke_cluster                           = "projects/${var.project_id}/locations/${module.cluster_dev.location}/clusters/${module.cluster_dev.name}"
      cloud_run_region                      = "projects/${var.project_id}/locations/${var.region}"
      require_approval                      = false
      binary_authorization_evaluation_mode  = "ALWAYS_ALLOW"
      binary_authorization_enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
    }
    test = {
      gke_cluster                           = "projects/${var.project_id}/locations/${module.cluster_test.location}/clusters/${module.cluster_test.name}"
      cloud_run_region                      = "projects/${var.project_id}/locations/${var.region}"
      require_approval                      = false
      binary_authorization_evaluation_mode  = "ALWAYS_ALLOW"
      binary_authorization_enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
    }
    prod = {
      gke_cluster                           = "projects/${var.project_id}/locations/${module.cluster_prod.location}/clusters/${module.cluster_prod.name}"
      cloud_run_region                      = "projects/${var.project_id}/locations/${var.region}"
      require_approval                      = true
      binary_authorization_evaluation_mode  = "REQUIRE_ATTESTATION"
      binary_authorization_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    }
  }

  cws_clusters = {
    default = {
      network    = module.vpc.name
      subnetwork = "hub"
      region     = var.region
    }
  }

  cws_configs = length(var.developers) > 0 ? {
    default = {
      cws_cluster             = "default"
      image                   = "us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest"
      machine_type            = var.machine_type_default
      persistent_disk_size_gb = 50
      creators                = [for dev, _ in var.developers : "user:${dev}"]
      instances = [
        for dev, _ in var.developers : {
          name         = "ws-${lower(replace(split("@", dev)[0], "/[^a-z0-9]/", "-"))}"
          display_name = "Workstation for ${split("@", dev)[0]}"
          users        = ["user:${dev}"]
        }
      ]
    }
  } : {}
}

module "cicd_foundation" {
  source = "github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v9.0.0"

  project_id = var.project_id

  # go/keep-sorted start
  apps = var.apps
  artifact_registry_readers = [
    module.sa_cluster_dev.iam_email,
    module.sa_cluster_test.iam_email,
    module.sa_cluster_prod.iam_email,
  ]
  artifact_registry_region               = coalesce(var.artifact_registry_region, var.region)
  boot_disk_size_gb_default              = var.boot_disk_size_gb_default
  build_machine_type_default             = var.build_machine_type_default
  build_source_retention_days            = var.build_source_retention_days
  build_timeout_default_seconds          = var.build_timeout_default
  cloud_build_region                     = coalesce(var.cloud_build_region, var.region)
  cws_clusters                           = local.cws_clusters
  cws_configs                            = local.cws_configs
  cws_custom_images                      = var.cws_custom_images
  default_agentic_instructions           = var.default_agentic_instructions
  default_agentic_location               = var.default_agentic_location
  default_agentic_model                  = var.default_agentic_model
  default_agentic_personas               = var.default_agentic_personas
  default_agentic_prompt                 = var.default_agentic_prompt
  deploy_region                          = var.region
  disable_public_ip_addresses_default    = var.disable_public_ip_addresses_default
  docker_image_tag                       = var.docker_image_tag
  enable_apis                            = var.enable_apis
  enable_nested_virtualization_default   = var.enable_nested_virtualization_default
  gcloud_image_tag                       = var.gcloud_image_tag
  git_branch_trigger                     = var.git_branch_trigger
  git_branches_regexp_trigger            = var.git_branch_trigger_regexp
  github_owner                           = local.effective_github_owner
  github_repo                            = local.effective_github_repo
  idle_timeout_seconds_default           = var.idle_timeout_seconds_default
  kms_keyring_location                   = var.region
  kritis_signer_image                    = var.kritis_signer_image
  machine_type_default                   = var.machine_type_default
  persistent_disk_fs_type_default        = var.persistent_disk_fs_type_default
  persistent_disk_reclaim_policy_default = var.persistent_disk_reclaim_policy_default
  persistent_disk_type_default           = var.persistent_disk_type_default
  pool_size_default                      = var.pool_size_default
  runtimes                               = var.runtimes
  scheduler_default_region               = var.region
  secret_manager_region                  = var.region
  secure_source_manager_always_create    = var.secure_source_manager_always_create
  secure_source_manager_region           = var.ssm_region
  skaffold_image_tag                     = var.skaffold_image_tag
  ssm_branch_rule                        = var.ssm_branch_rule
  stages                                 = local.stages
  # go/keep-sorted end
}
