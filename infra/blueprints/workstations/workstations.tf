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

# Cloud Workstation Cluster

resource "google_workstations_workstation_cluster" "cluster" {
  provider               = google-beta
  project                = var.project_id
  workstation_cluster_id = var.ws_cluster_name
  network                = module.vpc.id
  subnetwork             = module.vpc.subnets["${var.region}/${var.subnet_name}"].id
  location               = var.region
}

# Cloud Workstation Config

module "sa-ws" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v36.0.1"
  project_id   = google_workstations_workstation_cluster.cluster.project
  name         = var.sa_ws_name
  display_name = "Cloud Workstation Service Account"
  description  = "Terraform-managed."
}

resource "google_workstations_workstation_config" "admins" {
  provider               = google-beta
  for_each               = local.ws_configs
  project                = google_workstations_workstation_cluster.cluster.project
  workstation_config_id  = each.value.name
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = google_workstations_workstation_cluster.cluster.location
  idle_timeout           = "${var.ws_idle_time}s"
  host {
    gce_instance {
      machine_type                 = var.ws_config_machine_type
      boot_disk_size_gb            = var.ws_config_boot_disk_size_gb
      service_account              = module.sa-ws.email
      disable_public_ip_addresses  = var.ws_config_disable_public_ip
      pool_size                    = var.ws_pool_size
      enable_nested_virtualization = var.ws_nested_virtualization
    }
  }
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = var.ws_pd_disk_size_gb
      fs_type        = var.ws_pd_disk_fs_type
      disk_type      = var.ws_pd_disk_type
      reclaim_policy = var.ws_pd_disk_reclaim_policy
    }
  }
  container {
    image = "${module.docker_artifact_registry.url}/${each.value.image}:${var.ws_image_tag}"
  }
}

resource "google_workstations_workstation_config" "users" {
  provider               = google-beta
  for_each               = local.ws_configs
  project                = google_workstations_workstation_cluster.cluster.project
  workstation_config_id  = "${each.value.name}-prebuilt"
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = google_workstations_workstation_cluster.cluster.location
  idle_timeout           = "${var.ws_idle_time}s"
  host {
    gce_instance {
      machine_type                 = var.ws_config_machine_type
      boot_disk_size_gb            = var.ws_config_boot_disk_size_gb
      service_account              = module.sa-ws.email
      disable_public_ip_addresses  = var.ws_config_disable_public_ip
      pool_size                    = var.ws_pool_size
      enable_nested_virtualization = var.ws_nested_virtualization
    }
  }
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      source_snapshot = var.ws_pd_disk_snapshot_id
      disk_type       = var.ws_pd_disk_type
      reclaim_policy  = var.ws_pd_disk_reclaim_policy
    }
  }
  container {
    image = "${module.docker_artifact_registry.url}/${each.value.image}:${var.ws_image_tag}"
  }
}

data "google_iam_policy" "workstations_creator" {
  binding {
    role    = "roles/workstations.workstationCreator"
    members = [for user in var.users : "user:${user}"]
  }
}

resource "google_workstations_workstation_config_iam_policy" "users" {
  provider               = google-beta
  for_each               = local.ws_configs
  project                = google_workstations_workstation_config.admins[each.key].project
  location               = google_workstations_workstation_config.admins[each.key].location
  workstation_cluster_id = google_workstations_workstation_config.admins[each.key].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.admins[each.key].workstation_config_id
  policy_data            = data.google_iam_policy.workstations_creator.policy_data
}

# Cloud Scheduler

resource "google_project_iam_custom_role" "ws_image_build_runner" {
  project     = google_workstations_workstation_cluster.cluster.project
  role_id     = "cwsBuildRunner"
  title       = "Cloud Workstation Image Build Runner"
  description = "Terraform managed."
  permissions = [
    "cloudbuild.builds.create",
  ]
}

module "sa-ws-image-build-runner" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v36.0.1"
  project_id   = google_workstations_workstation_cluster.cluster.project
  name         = "workstation-image-build-runner"
  display_name = "Cloud Workstation Image Build Runner Service Account"
  description  = "Terraform-managed."
  iam_sa_roles = {
    (module.sa-cb.id) : [
      "roles/iam.serviceAccountUser",
    ]
  }
}

resource "google_project_iam_member" "ws_image_build_runner" {
  project = module.project.id
  role    = google_project_iam_custom_role.ws_image_build_runner.name
  member  = module.sa-ws-image-build-runner.iam_email
}

# cf. https://cloud.google.com/workstations/docs/tutorial-automate-container-image-rebuild
resource "google_cloud_scheduler_job" "ws_image" {
  for_each    = { for image, config in var.apps : image => config if config.runtime == "workstation" }
  project     = google_workstations_workstation_cluster.cluster.project
  region      = google_workstations_workstation_cluster.cluster.location
  name        = "${each.key}-nightly"
  description = "Terraform-managed."
  schedule    = "0 1 * * *"
  paused      = false
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${google_cloudbuild_trigger.continuous-integration[each.key].project}/locations/${google_cloudbuild_trigger.continuous-integration["${each.key}"].location}/triggers/${google_cloudbuild_trigger.continuous-integration["${each.key}"].trigger_id}:run"
    oauth_token {
      service_account_email = module.sa-ws-image-build-runner.email
    }
  }
}
