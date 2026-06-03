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

module "vpc" {
  count = var.create_vpc ? 1 : 0

  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v49.0.0"

  project_id = var.project_id
  name       = var.vpc_name
  subnets = [
    {
      ip_cidr_range = var.subnet_cidr
      name          = var.subnet_name
      region        = var.vpc_region
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.psa_cidr
    }
  }]

  depends_on = [data.google_project.project]
}

module "fw" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v49.0.0"

  project_id = var.project_id
  network    = var.create_vpc ? module.vpc[0].name : var.vpc_name
  factories_config = {
    rules_folder  = "firewall/rules"
    cidr_tpl_file = "firewall/cidrs.yaml"
  }

  depends_on = [data.google_project.project]
}

module "nat" {
  count = local.deploy_nat ? 1 : 0

  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v49.0.0"

  project_id     = var.project_id
  region         = var.vpc_region
  name           = "${var.vpc_name}-nat"
  router_network = var.create_vpc ? module.vpc[0].name : var.vpc_name
  router_create  = true

  router_name = "${var.vpc_name}-router"
}
