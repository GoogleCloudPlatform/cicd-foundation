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

module "vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v45.0.0"
  project_id = var.project_id
  name       = "vpc"
  vpc_reuse  = var.vpc_create ? null : {}
  subnets = [
    {
      ip_cidr_range = var.vpc_hub_primary_cidr
      name          = "hub"
      region        = var.region
    },
    {
      ip_cidr_range = var.cluster_dev_network_config.nodes_cidr_block
      name          = "dev"
      region        = var.region
      secondary_ip_ranges = {
        pods     = { ip_cidr_range = var.cluster_dev_network_config.pods_cidr_block }
        services = { ip_cidr_range = var.cluster_dev_network_config.services_cidr_block }
      }
    },
    {
      ip_cidr_range = var.cluster_test_network_config.nodes_cidr_block
      name          = "test"
      region        = var.region
      secondary_ip_ranges = {
        pods     = { ip_cidr_range = var.cluster_test_network_config.pods_cidr_block }
        services = { ip_cidr_range = var.cluster_test_network_config.services_cidr_block }
      }
    },
    {
      ip_cidr_range = var.cluster_prod_network_config.nodes_cidr_block
      name          = "prod"
      region        = var.region
      secondary_ip_ranges = {
        pods     = { ip_cidr_range = var.cluster_prod_network_config.pods_cidr_block }
        services = { ip_cidr_range = var.cluster_prod_network_config.services_cidr_block }
      }
    },
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.proxy_only_subnet_cidr_block
      name          = "proxy"
      region        = var.region
      active        = true
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.vpc_hub_psa_cidr
    }
  }]
}

module "nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v45.0.0"
  project_id     = var.project_id
  region         = var.region
  name           = var.nat_name
  router_network = module.vpc.name
}

module "fw" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v45.0.0"
  project_id = var.project_id
  network    = module.vpc.name
  factories_config = {
    rules_folder  = "${path.module}/firewall/rules"
    cidr_tpl_file = "${path.module}/firewall/cidrs.yaml"
  }
}
