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

output "ws_cluster_id" {
  value = google_workstations_workstation_cluster.cicd_foundation.workstation_cluster_id
}

output "ws_config_id" {
  value = google_workstations_workstation_config.cicd_foundation.workstation_config_id
}

output "workstations_sa_email" {
  value = module.sa-ws.email
}

output "webhook_trigger_secret" {
  value = google_secret_manager_secret_version.webhook_trigger.id
}

output "ssm_instance_name" {
  value = google_secure_source_manager_instance.source.name
}

output "kritis_note" {
  value = google_container_analysis_note.vulnz-attestor.id
}

output "kms_key_name" {
  value = data.google_kms_crypto_key_version.vulnz-attestor.name
}

output "cloud_build_sa_id" {
  value = module.sa-cb.id
}

output "cloud_build_sa_email" {
  value = module.sa-cb.email
}

output "cloud_build_robot_sa_email" {
  value = module.project.service_agents["cloudbuild"].iam_email
}

output "sa-cluster-prod_email" {
  value = module.sa-cluster-prod.email
}

output "sa-cluster-test_email" {
  value = module.sa-cluster-test.email
}

output "sa-cluster-dev_email" {
  value = module.sa-cluster-dev.email
}

output "cd_target_cluster-prod" {
  value = google_clouddeploy_target.cluster-prod.name
}

output "cd_target_cluster-test" {
  value = google_clouddeploy_target.cluster-test.name
}

output "cd_target_cluster-dev" {
  value = google_clouddeploy_target.cluster-dev.name
}

output "cd_target_run-prod" {
  value = google_clouddeploy_target.run-prod.name
}

output "cd_target_run-test" {
  value = google_clouddeploy_target.run-test.name
}

output "cd_target_run-dev" {
  value = google_clouddeploy_target.run-dev.name
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
