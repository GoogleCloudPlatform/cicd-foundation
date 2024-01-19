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

output "cloud_build_sa_email" {
  value = module.sa-cb.email
}

output "cloud_build_sa_id" {
  value = module.sa-cb.id
}

output "cloud_deploy_robot_sa_email" {
  value = module.project.service_accounts.robots["clouddeploy"]
}

output "cloud_build_robot_sa_email" {
  value = module.project.service_accounts.robots["cloudbuild"]
}

output "vpc_self_link" {
  value = module.vpc.self_link
}

output "vpc_hub_subnet_self_link" {
  value = module.vpc.subnet_self_links["${var.region}/hub"]
}

output "vpc_dev_subnet_self_link" {
  value = module.vpc.subnet_self_links["${var.region}/dev"]
}

output "vpc_test_subnet_self_link" {
  value = module.vpc.subnet_self_links["${var.region}/test"]
}

output "vpc_prod_subnet_self_link" {
  value = module.vpc.subnet_self_links["${var.region}/prod"]
}
