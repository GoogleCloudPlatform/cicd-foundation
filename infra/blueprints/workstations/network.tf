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
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v36.0.1"
  project_id = var.project_id
  name       = var.vpc_name
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.subnet_cidr
      name          = var.subnet_name
      region        = var.region
    },
  ]
  psa_configs = [{
    ranges = {
      "default" = var.psa_cidr
    }
  }]
}

module "fw" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v36.0.1"
  project_id = var.project_id
  network    = module.vpc.name
  factories_config = {
    rules_folder  = "firewall/rules"
    cidr_tpl_file = "firewall/cidrs.yaml"
  }
}
