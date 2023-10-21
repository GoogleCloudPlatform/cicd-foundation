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

module "hub" {
  source         = "./hub"
  project_hub_id = var.project_hub_id
}

module "team" {
  source             = "./team"
  team-prefix        = "team1"
  project_hub_id     = var.project_hub_id
  project_service_id = var.project_service_id
  sa-cb-email        = module.hub.cloud_build_sa_email
  sa-cb-id           = module.hub.cloud_build_sa_id

  kritis_signer_image = var.kritis_signer_image

  github_owner = var.github_owner
  github_repo_name = var.github_repo_name
  github_branch = var.github_branch

  cloud_build_robot_sa_email  = module.hub.cloud_build_robot_sa_email
  cloud_deploy_robot_sa_email = module.hub.cloud_deploy_robot_sa_email

  vpc_hub_self_link         = module.hub.vpc_hub_self_link
  vpc_hub_subnet_self_link  = module.hub.vpc_hub_subnet_self_link
  vpc_dev_subnet_self_link  = module.hub.vpc_dev_subnet_self_link
  vpc_test_subnet_self_link = module.hub.vpc_test_subnet_self_link
  vpc_prod_subnet_self_link = module.hub.vpc_prod_subnet_self_link
}
