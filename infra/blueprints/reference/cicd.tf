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
  stages = {
    for env_key, env in var.environments : env_key => {
      order                                 = env.order
      project_id                            = module.project_spoke_supplychain[env_key].project_id
      runtime_project_id                    = module.project_spoke_service[env_key].project_id
      gke_cluster                           = "projects/${module.project_spoke_service[env_key].project_id}/locations/${module.cluster[env_key].location}/clusters/${module.cluster[env_key].name}"
      gke_internal_ip                       = env.gke_internal_ip
      cloud_run_region                      = "projects/${module.project_spoke_service[env_key].project_id}/locations/${var.region}"
      peered_network                        = module.vpc_spoke_build[env_key].id
      require_approval                      = env.require_approval
      canary_percentages                    = env.canary_percentages
      canary_verify                         = env.canary_verify
      binary_authorization_evaluation_mode  = env.binary_authorization_evaluation_mode
      binary_authorization_enforcement_mode = env.binary_authorization_enforcement_mode
    }
  }

  apps = {
    for app_key, app in var.apps : app_key => merge(app, {
      stages = {
        for env_key in keys(var.environments) :
        env_key => lookup(coalesce(app.stages, {}), env_key, {})
      }
    })
  }

  cws_clusters = {
    default = {
      network     = module.vpc_hub.name
      subnetwork  = var.vpc_subnet_name
      region      = var.region
      vpc_project = module.project_hub_host.project_id
    }
  }

  workstation_developer_users = [
    for dev in local.developer_iam_members : dev
    if startswith(dev, "user:")
  ]

  cws_configs = length(local.developer_iam_members) > 0 ? {
    default = {
      cws_cluster             = "default"
      image                   = "us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest"
      machine_type            = var.machine_type_default
      persistent_disk_size_gb = var.ws_pd_disk_size_gb
      creators                = local.developer_iam_members
      instances = [
        for dev in local.workstation_developer_users : {
          name         = "ws-${lower(replace(split("@", trimprefix(dev, "user:"))[0], "/[^a-z0-9]/", "-"))}"
          display_name = "Workstation for ${split("@", trimprefix(dev, "user:"))[0]}"
          users        = [dev]
        }
      ]
    }
  } : {}
}

module "cicd_foundation" {
  source = "github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v9.0.0"

  project_id = module.project_hub_supplychain.project_id

  # go/keep-sorted start
  apps = local.apps
  artifact_registry_readers = concat(
    [for env_key in sort(keys(var.environments)) : module.sa_cluster[env_key].iam_email],
    ["serviceAccount:service-${module.project_hub_supplychain.number}@gcp-sa-workstationsvm.iam.gserviceaccount.com"],
  )
  artifact_registry_region               = coalesce(var.artifact_registry_region, var.region)
  boot_disk_size_gb_default              = var.boot_disk_size_gb_default
  build_machine_type_default             = var.build_machine_type_default
  build_source_retention_days            = var.build_source_retention_days
  build_timeout_default_seconds          = var.build_timeout_default
  canary_route_update_wait_time_seconds  = var.canary_route_update_wait_time_seconds
  cloud_build_pool_disk_size_gb          = var.cb_pool_disk_size_gb
  cloud_build_pool_machine_type          = var.cb_pool_machine_type
  cloud_build_pool_name                  = var.cb_pool_name
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
  enable_apis                            = false
  enable_nested_virtualization_default   = var.enable_nested_virtualization_default
  gcloud_image_tag                       = var.gcloud_image_tag
  git_branch_trigger                     = var.git_branch_trigger
  git_branches_regexp_trigger            = var.git_branch_trigger_regexp
  github_owner                           = var.github_owner
  github_repo                            = var.github_repo
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
