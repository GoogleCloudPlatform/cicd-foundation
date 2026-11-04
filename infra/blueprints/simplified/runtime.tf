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

module "sa_cluster_prod" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = var.project_id
  name         = "${var.sa_cluster_name}-prod"
  display_name = "GKE (prod) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) = var.cluster_roles
  }
}

module "sa_cluster_test" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = var.project_id
  name         = "${var.sa_cluster_name}-test"
  display_name = "GKE (test) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) = var.cluster_roles
  }
}

module "sa_cluster_dev" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = var.project_id
  name         = "${var.sa_cluster_name}-dev"
  display_name = "GKE (dev) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) = var.cluster_roles
  }
}

module "cluster_prod" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = var.project_id
  name                = "${var.cluster_name}-prod"
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/prod"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster_prod_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = false
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster_prod_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = true
  }
  node_config = {
    service_account = module.sa_cluster_prod.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_prod_peering_routes" {
  project              = var.project_id
  network              = module.vpc.name
  peering              = module.cluster_prod.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}

module "cluster_test" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = var.project_id
  name                = "${var.cluster_name}-test"
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/test"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster_test_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = false
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster_test_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = true
  }
  node_config = {
    service_account = module.sa_cluster_test.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_test_peering_routes" {
  project              = var.project_id
  network              = module.vpc.name
  peering              = module.cluster_test.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}

module "cluster_dev" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = var.project_id
  name                = "${var.cluster_name}-dev"
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/dev"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster_dev_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = false
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster_dev_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = true
  }
  node_config = {
    service_account = module.sa_cluster_dev.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_dev_peering_routes" {
  project              = var.project_id
  network              = module.vpc.name
  peering              = module.cluster_dev.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}
