# Copyright 2023-2024 Google LLC
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
  source     = "./hub"
  project_id = var.project_id
  region     = var.region
  developers = formatlist("user:%s", keys(var.developers))
}

module "team" {
  for_each = var.developers

  source      = "./team"
  team-prefix = join("", regexall("[a-zA-Z]", split("@", each.key)[0]))
  project_id  = var.project_id
  sa-cb-email = module.hub.cloud_build_sa_email
  sa-cb-id    = module.hub.cloud_build_sa_id

  kritis_signer_image = var.kritis_signer_image

  github_owner  = each.value.github_user
  github_repo   = each.value.github_repo
  github_branch = var.github_branch

  cloud_build_robot_sa_email  = module.hub.cloud_build_robot_sa_email
  cloud_deploy_robot_sa_email = module.hub.cloud_deploy_robot_sa_email

  vpc_self_link             = module.hub.vpc_self_link
  vpc_hub_subnet_self_link  = module.hub.vpc_hub_subnet_self_link
  vpc_dev_subnet_self_link  = module.hub.vpc_dev_subnet_self_link
  vpc_test_subnet_self_link = module.hub.vpc_test_subnet_self_link
  vpc_prod_subnet_self_link = module.hub.vpc_prod_subnet_self_link

  depends_on = [
    module.hub,
  ]
}
