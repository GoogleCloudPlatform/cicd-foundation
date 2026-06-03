# Copyright 2024-2025 Google LLC
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
  target_names       = keys(var.android_targets)
  has_android_builds = length(var.android_branches) > 0 && length(local.target_names) > 0

  # Generate all combinations of config, branch, and target
  cws_combinations = flatten([
    for config_key, config_value in var.cws_configs : [
      for item in setproduct(var.android_branches, local.target_names) :
      {
        config_key   = config_key
        config_value = config_value
        branch       = item[0]
        target       = item[1]
      }
    ]
  ])

  # Build the cws_configs_product map from the combinations
  cws_configs_product = local.has_android_builds ? {
    for combo in local.cws_combinations :
    "${combo.config_key}-${lower(combo.branch)}-${lower(combo.target)}" => merge(
      combo.config_value,
      {
        instances = [for i in coalesce(combo.config_value.instances, []) : {
          # The 'name' combines elements reflecting the instance name, branch,
          # and target from the combination.
          # Note that the final name will be constructed by the cicd_foundation
          # module and will incorporate the custom image name and a short hash
          # of the full name to ensure uniqueness.
          name = join("-", [
            lower(substr(i.name, 0, 12)),
            lower(substr(join("-", [for part in split("-", combo.branch) : substr(part, 0, 6)]), 0, 7)),
            lower(substr(join("-", [for part in split("-", combo.target) : substr(part, 0, 6)]), 0, 7)),
          ])
          display_name = "${i.name}-${combo.branch}-${combo.target}"
          users        = i.users
        }]
      }
    )
  } : var.cws_configs
  # Final decision on Cloud NAT deployment
  deploy_nat = var.create_cloud_nat != null ? var.create_cloud_nat : (var.disable_public_ip_addresses_default || anytrue([
    for k, v in var.cws_configs : coalesce(v.disable_public_ip_addresses, var.disable_public_ip_addresses_default)
  ]))
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project_services
  ]
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.2.0"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = false
  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}
