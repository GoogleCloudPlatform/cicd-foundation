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

locals {
  activate_apis = concat([
    "artifactregistry.googleapis.com",
  ], var.secure_source_manager_create_ca_pool && var.secure_source_manager_ca_pool == null ? ["privateca.googleapis.com"] : [])
  all_apps = merge(local.cws_apps, var.apps)
  # Configuration for custom images used in Cloud Workstations.
  # The 'runtime' is set to "workstations" to indicate these are for Cloud Workstations.
  # Other fields like build and workstation_config are extracted from the input variable.
  cws_apps = {
    for k, v in var.cws_custom_images : k => {
      runtime = "workstations"
      build = {
        skaffold_path   = try(v.build.skaffold_path, null)
        timeout_seconds = try(v.build.timeout_seconds, null)
        machine_type    = try(v.build.machine_type, null)
        env             = try(v.build.env, {})
        included_files  = try(v.build.included_files, [])
      }
      workstation_config = {
        scheduler_region = try(v.workstation_config.scheduler_region, null)
        ci_schedule      = try(v.workstation_config.ci_schedule, null)
        paused           = try(v.workstation_config.paused, false)
      }
      git_repo = v.git_repo
      github   = v.github
      ssm      = v.ssm
    }
  }
  default_labels = {
    "tf_module_github_org"  = "GoogleCloudPlatform"
    "tf_module_github_repo" = "cicd-foundation"
    "tf_module_name"        = "cicd_foundation"
    "tf_module_version"     = "v8-0-0"
  }
  # merge the default labels with the user-provided labels and convert to lowercase
  common_labels = {
    for k, v in merge(var.labels, local.default_labels) : lower(k) => lower(v)
  }
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project_services
  ]
}

module "project_services_cloud_resourcemanager" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.1.0"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = false
  activate_apis = [
    "cloudresourcemanager.googleapis.com"
  ]
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.1.0"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = false
  activate_apis               = local.activate_apis

  depends_on = [
    module.project_services_cloud_resourcemanager
  ]
}
