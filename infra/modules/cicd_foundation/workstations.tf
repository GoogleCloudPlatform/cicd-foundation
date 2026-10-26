# Copyright 2023-2026 Google LLC
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
  cws_configs_hydrated = {
    for item in flatten([
      for config_key, config_value in var.cws_configs :
      (length(coalesce(config_value.custom_image_names, [])) > 0 ? [
        for custom_image_name in config_value.custom_image_names : {
          key = "${config_key}-${custom_image_name}"
          value = merge(
            config_value,
            {
              # Generate the image name using the custom image name and the artifact registry repository URI.
              image              = "${module.cicd_pipelines[0].artifact_registry_repository_uri}/${custom_image_name}:latest"
              custom_image_names = []
              display_name       = coalesce(config_value.display_name, "${config_key}-${custom_image_name}")
              instances = [
                for instance in coalesce(config_value.instances, []) :
                # The 'name' is constructed to be unique and descriptive, adhering to GCP's maximum resource name length.
                # It combines elements reflecting the instance name and the generated image name.
                # A short hash of the combined string is appended to ensure uniqueness.
                merge(instance, {
                  name         = "${substr(instance.name, 0, 28)}-${substr(custom_image_name, 0, 27)}-${substr(sha256("${instance.name}-${custom_image_name}"), 0, 4)}"
                  display_name = "${instance.name}-${custom_image_name}"
                })
              ]
            }
          )
        }
        ] : [
        {
          key = config_key
          value = merge(
            config_value,
            {
              instances = coalesce(config_value.instances, [])
            }
          )
        }
      ])
    ]) : item.key => item.value
  }
}

module "workstations" {
  source = "./cicd_workstations"

  project_id                             = data.google_project.project.project_id
  enable_apis                            = var.enable_apis
  labels                                 = local.common_labels
  cws_clusters                           = var.cws_clusters
  cws_configs                            = local.cws_configs_hydrated
  cws_scopes                             = var.cws_scopes
  cws_service_account_name               = var.cws_service_account_name
  boot_disk_size_gb_default              = var.boot_disk_size_gb_default
  disable_public_ip_addresses_default    = var.disable_public_ip_addresses_default
  enable_nested_virtualization_default   = var.enable_nested_virtualization_default
  idle_timeout_seconds_default           = var.idle_timeout_seconds_default
  machine_type_default                   = var.machine_type_default
  pool_size_default                      = var.pool_size_default
  persistent_disk_fs_type_default        = var.persistent_disk_fs_type_default
  persistent_disk_reclaim_policy_default = var.persistent_disk_reclaim_policy_default
  persistent_disk_type_default           = var.persistent_disk_type_default
}

resource "google_artifact_registry_repository_iam_member" "workstation_artifactregistry_reader" {
  count = length(var.cws_custom_images) > 0 ? 1 : 0

  project    = module.cicd_pipelines[0].artifact_registry_repository.project
  location   = module.cicd_pipelines[0].artifact_registry_repository.location
  repository = module.cicd_pipelines[0].artifact_registry_repository.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.workstations.cws_service_account_email}"

  depends_on = [
    module.cicd_pipelines
  ]
}
