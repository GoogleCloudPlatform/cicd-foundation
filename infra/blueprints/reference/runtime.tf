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

module "sa-cluster-prod" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = module.project_prod_service.id
  name         = var.sa_cluster_name
  display_name = "GKE (prod) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project_prod_service.id) = var.cluster_roles
  }
}

module "sa-cluster-test" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = module.project_test_service.id
  name         = var.sa_cluster_name
  display_name = "GKE (test) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project_test_service.id) = var.cluster_roles
  }
}

module "sa-cluster-dev" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"
  project_id   = module.project_dev_service.id
  name         = var.sa_cluster_name
  display_name = "GKE (dev) Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project_dev_service.id) = var.cluster_roles
  }
}

module "cluster-prod" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = module.project_prod_service.project_id
  name                = var.cluster_name
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc-prod.self_link
    subnetwork = module.vpc-prod.subnet_self_links["${var.region}/${var.vpc_subnet_name}"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster-prod_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = true
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster-prod_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = true
  }
  node_config = {
    service_account = module.sa-cluster-prod.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_prod_peering_routes" {
  project              = module.project_prod_host.project_id
  network              = module.vpc-prod.name
  peering              = module.cluster-prod.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}

module "cluster-test" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = module.project_test_service.project_id
  name                = var.cluster_name
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc-test.self_link
    subnetwork = module.vpc-test.subnet_self_links["${var.region}/${var.vpc_subnet_name}"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster-test_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = true
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster-test_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = true
  }
  node_config = {
    service_account = module.sa-cluster-test.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_test_peering_routes" {
  project              = module.project_test_host.project_id
  network              = module.vpc-test.name
  peering              = module.cluster-test.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}

module "cluster-dev" {
  source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gke-cluster-autopilot?ref=v45.0.0"
  project_id          = module.project_dev_service.project_id
  name                = var.cluster_name
  location            = var.region
  release_channel     = var.cluster_release_channel
  min_master_version  = var.cluster_min_version
  deletion_protection = var.cluster_deletion_protection
  vpc_config = {
    network    = module.vpc-dev.self_link
    subnetwork = module.vpc-dev.subnet_self_links["${var.region}/${var.vpc_subnet_name}"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }
  access_config = {
    ip_access = {
      authorized_ranges       = var.cluster-dev_network_config.master_authorized_cidr_blocks
      disable_public_endpoint = false
      private_endpoint_config = {
        global_access = true
      }
    }
    master_ipv4_cidr_block = var.cluster-dev_network_config.master_cidr_block
    private_nodes          = true
  }
  enable_features = {
    binary_authorization = false
  }
  node_config = {
    service_account = module.sa-cluster-dev.email
    tags = [
      "http-server",
      "https-server",
    ]
  }
}

resource "google_compute_network_peering_routes_config" "cluster_dev_peering_routes" {
  project              = module.project_dev_host.project_id
  network              = module.vpc-dev.name
  peering              = module.cluster-dev.cluster.private_cluster_config[0].peering_name
  export_custom_routes = true
  import_custom_routes = false
}
