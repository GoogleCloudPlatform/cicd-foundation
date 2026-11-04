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

module "sa_cluster" {
  for_each     = var.environments
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = module.project_spoke_service[each.key].id
  name         = var.sa_cluster_name
  display_name = "GKE (${each.key}) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project_spoke_service[each.key].id) = var.cluster_roles
  }
}

module "cluster" {
  for_each            = var.environments
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = module.project_spoke_service[each.key].project_id
  name                = var.cluster_name
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc_spoke[each.key].self_link
    subnetwork = module.vpc_spoke[each.key].subnet_self_links["${var.region}/${var.vpc_subnet_name}"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = each.value.network.master_authorized_cidr_blocks
      disable_public_endpoint = each.value.disable_public_endpoint
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = each.value.network.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = each.value.enable_binary_authorization
  }
  node_config = {
    service_account = module.sa_cluster[each.key].email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_peering_routes" {
  for_each             = var.environments
  project              = module.project_spoke_host[each.key].project_id
  network              = module.vpc_spoke[each.key].name
  peering              = module.cluster[each.key].cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}
