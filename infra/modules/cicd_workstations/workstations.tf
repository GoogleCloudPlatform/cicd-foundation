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
  # Reconstruct the clusters map with fully qualified paths for network and subnetwork.
  cws_clusters = {
    for k, v in var.cws_clusters : k => merge(v, {
      network    = "projects/${coalesce(v.vpc_project, data.google_project.project.project_id)}/global/networks/${v.network}"
      subnetwork = "projects/${coalesce(v.vpc_project, data.google_project.project.project_id)}/regions/${v.region}/subnetworks/${v.subnetwork}"
    })
  }
  # Map each config key to its corresponding Cloud Workstation Cluster resource.
  config_to_cluster_map = {
    for config_key, config_value in var.cws_configs : config_key =>
    google_workstations_workstation_cluster.cluster[config_value.cws_cluster]
  }
  # Filter configurations to only those that have a list of creators.
  configs_with_creators = {
    for key, config in var.cws_configs : key => config
    if length(coalesce(config.creators, [])) > 0
  }
  # Flatten the nested list of instances across all configurations into a single map for easier iteration.
  workstation_map = {
    for item in flatten([
      for config_key, config_value in var.cws_configs : [
        for instance in config_value.instances : {
          resource_key = "${config_key}-${instance.name}"
          ws_name      = instance.name
          display_name = coalesce(instance.display_name, config_value.display_name, instance.name)
          config_key   = config_key
          users        = instance.users
        }
      ]
    ]) : item.resource_key => item
  }
}

# Cloud Workstation Clusters
resource "google_workstations_workstation_cluster" "cluster" {
  for_each = local.cws_clusters
  provider = google-beta

  project                = data.google_project.project.project_id
  workstation_cluster_id = each.key
  network                = each.value.network
  subnetwork             = each.value.subnetwork
  location               = each.value.region
  labels                 = local.common_labels

  dynamic "domain_config" {
    for_each = each.value.domain_config != null ? [each.value.domain_config] : []

    content {
      domain = domain_config.value.domain
    }
  }

  dynamic "private_cluster_config" {
    for_each = each.value.private_cluster_config != null ? [each.value.private_cluster_config] : []

    content {
      enable_private_endpoint = private_cluster_config.value.enable_private_endpoint
    }
  }

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

# Cloud Workstation Configs
resource "google_workstations_workstation_config" "config" {
  for_each = var.cws_configs
  provider = google-beta

  project                = local.config_to_cluster_map[each.key].project
  workstation_config_id  = each.key
  workstation_cluster_id = local.config_to_cluster_map[each.key].workstation_cluster_id
  location               = local.config_to_cluster_map[each.key].location
  display_name           = each.value.display_name
  idle_timeout           = "${coalesce(each.value.idle_timeout_seconds, var.idle_timeout_seconds_default)}s"
  dynamic "container" {
    for_each = each.value.image != null ? [1] : []

    content {
      image = each.value.image
    }
  }
  host {
    gce_instance {
      machine_type                 = coalesce(each.value.machine_type, var.machine_type_default)
      boot_disk_size_gb            = coalesce(each.value.boot_disk_size_gb, var.boot_disk_size_gb_default)
      service_account              = module.cws_service_account.email
      service_account_scopes       = var.cws_scopes
      disable_public_ip_addresses  = coalesce(each.value.disable_public_ip_addresses, var.disable_public_ip_addresses_default)
      pool_size                    = coalesce(each.value.pool_size, var.pool_size_default)
      enable_nested_virtualization = coalesce(each.value.enable_nested_virtualization, var.enable_nested_virtualization_default)
      dynamic "accelerators" {
        for_each = coalesce(each.value.accelerators, [])

        content {
          type  = accelerators.value.type
          count = accelerators.value.count
        }
      }
      dynamic "shielded_instance_config" {
        for_each = each.value.shielded_instance_config == null ? [] : [each.value.shielded_instance_config]

        content {
          enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
          enable_vtpm                 = shielded_instance_config.value.enable_vtpm
          enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
        }
      }
      dynamic "boost_configs" {
        for_each = coalesce(each.value.boost_configs, [])

        content {
          id                           = boost_configs.value.id
          machine_type                 = boost_configs.value.machine_type
          boot_disk_size_gb            = boost_configs.value.boot_disk_size_gb
          enable_nested_virtualization = boost_configs.value.enable_nested_virtualization
          pool_size                    = boost_configs.value.pool_size
          dynamic "accelerators" {
            for_each = coalesce(boost_configs.value.accelerators, [])

            content {
              type  = accelerators.value.type
              count = accelerators.value.count
            }
          }
        }
      }
    }
  }
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      source_snapshot = each.value.persistent_disk_source_snapshot
      size_gb         = each.value.persistent_disk_size_gb
      fs_type         = each.value.persistent_disk_source_snapshot == null ? coalesce(each.value.persistent_disk_fs_type, var.persistent_disk_fs_type_default) : each.value.persistent_disk_fs_type
      disk_type       = coalesce(each.value.persistent_disk_type, var.persistent_disk_type_default)
      reclaim_policy  = coalesce(each.value.persistent_disk_reclaim_policy, var.persistent_disk_reclaim_policy_default)
    }
  }
  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

# IAM policy for granting the ability to create Cloud Workstation instances
# out of the Cloud Workstation Config.
# cf. https://cloud.google.com/iam/docs/roles-permissions/workstations#workstations.workstationCreator
data "google_iam_policy" "creators" {
  for_each = local.configs_with_creators

  binding {
    role    = "roles/workstations.workstationCreator"
    members = [for user in each.value.creators : "user:${user}"]
  }
}

# Resource to apply the IAM policy to each Cloud Workstation Config.
resource "google_workstations_workstation_config_iam_policy" "creators" {
  for_each = local.configs_with_creators
  provider = google-beta

  project                = google_workstations_workstation_config.config[each.key].project
  location               = google_workstations_workstation_config.config[each.key].location
  workstation_cluster_id = google_workstations_workstation_config.config[each.key].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.config[each.key].workstation_config_id
  policy_data            = data.google_iam_policy.creators[each.key].policy_data

  depends_on = [google_workstations_workstation_config.config]
}

# Cloud Workstation instances
resource "google_workstations_workstation" "workstation" {
  for_each = local.workstation_map
  provider = google-beta

  project                = local.config_to_cluster_map[each.value.config_key].project
  workstation_cluster_id = local.config_to_cluster_map[each.value.config_key].workstation_cluster_id
  location               = local.config_to_cluster_map[each.value.config_key].location
  workstation_config_id  = google_workstations_workstation_config.config[each.value.config_key].workstation_config_id
  workstation_id         = each.value.ws_name
  display_name           = each.value.display_name
  labels                 = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

# IAM policy for granting the ability to use Cloud Workstation instances.
# cf. https://cloud.google.com/iam/docs/roles-permissions/workstations#workstations.user
data "google_iam_policy" "users" {
  for_each = local.workstation_map

  binding {
    role    = "roles/workstations.user"
    members = [for user in each.value.users : "user:${user}"]
  }
}

# Resource to apply the IAM policy to each Cloud Workstation instance.
resource "google_workstations_workstation_iam_policy" "iam_policies" {
  for_each = local.workstation_map
  provider = google-beta

  project                = google_workstations_workstation.workstation[each.key].project
  location               = google_workstations_workstation.workstation[each.key].location
  workstation_cluster_id = google_workstations_workstation.workstation[each.key].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation.workstation[each.key].workstation_config_id
  workstation_id         = google_workstations_workstation.workstation[each.key].workstation_id
  policy_data            = data.google_iam_policy.users[each.key].policy_data
}
