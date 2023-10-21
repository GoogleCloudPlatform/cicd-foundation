# Copyright 2023 Google LLC
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

data "google_compute_network" "network" {
  project = module.project_hub.project_id
  name    = "default"
}

data "google_compute_subnetwork" "subnetwork" {
  project = module.project_hub.project_id
  name    = "default"
  region  = var.region
}

resource "google_workstations_workstation_cluster" "sweets" {
  provider               = google-beta
  project                = module.project_hub.project_id
  workstation_cluster_id = var.ws_cluster_name
  network                = module.vpc-hub.id
  subnetwork             = module.vpc-hub.subnets["${var.region}/hub"].id
  location               = var.region
}

resource "google_workstations_workstation_config" "sweets" {
  provider               = google-beta
  project                = module.project_hub.project_id
  workstation_config_id  = var.ws_config_name
  workstation_cluster_id = google_workstations_workstation_cluster.sweets.workstation_cluster_id
  location               = var.region
  host {
    gce_instance {
      machine_type                = var.ws_config_machine_type
      boot_disk_size_gb           = var.ws_config_boot_disk_size_gb
      disable_public_ip_addresses = var.ws_config_disable_public_ip
    }
  }
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb        = 200
      fs_type        = "ext4"
      disk_type      = "pd-standard"
      reclaim_policy = "DELETE"
    }
  }
}

resource "google_workstations_workstation" "sweets" {
  provider               = google-beta
  project                = module.project_hub.project_id
  workstation_id         = var.ws_name
  workstation_config_id  = google_workstations_workstation_config.sweets.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.sweets.workstation_cluster_id
  location               = var.region
}
