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

# go/keep-sorted start block=yes newline_separated=yes
output "cloud_build_trigger_github_connection_needed" {
  description = "Instructions to connect GitHub repository if using GitHub source."
  value       = module.cicd_foundation.cloud_build_trigger_github_connection_needed
}

output "cloud_build_trigger_ids" {
  description = "The full resource IDs of the Cloud Build triggers."
  value       = module.cicd_foundation.cloud_build_trigger_ids
}

output "cloud_build_trigger_trigger_ids" {
  description = "The unique short IDs of the Cloud Build triggers."
  value       = module.cicd_foundation.cloud_build_trigger_trigger_ids
}

output "cluster_dev_id" {
  description = "The fully-qualified ID of the development GKE cluster."
  value       = module.cluster-dev.id
}

output "cluster_prod_id" {
  description = "The fully-qualified ID of the production GKE cluster."
  value       = module.cluster-prod.id
}

output "cluster_test_id" {
  description = "The fully-qualified ID of the test GKE cluster."
  value       = module.cluster-test.id
}

output "cws_clusters" {
  description = "A map of Cloud Workstation clusters, with their IDs and other attributes."
  value       = module.cicd_foundation.cws_clusters
}

output "cws_service_account_email" {
  description = "The email address of the Cloud Workstations Service Account."
  value       = module.cicd_foundation.cws_service_account_email
}

output "secure_source_manager_instance_git_http" {
  description = "The Git HTTP URI of the created Secure Source Manager instance."
  value       = module.cicd_foundation.secure_source_manager_instance_git_http
}

output "secure_source_manager_instance_git_ssh" {
  description = "The Git SSH URI of the created Secure Source Manager instance."
  value       = module.cicd_foundation.secure_source_manager_instance_git_ssh
}

output "secure_source_manager_instance_html" {
  description = "The HTML hostname of the created Secure Source Manager instance."
  value       = module.cicd_foundation.secure_source_manager_instance_html
}

output "secure_source_manager_repository_git_html" {
  description = "The Git HTML URI of the created Secure Source Manager repository."
  value       = module.cicd_foundation.secure_source_manager_repository_git_html
}

output "secure_source_manager_repository_git_https" {
  description = "The Git HTTP URI of the created Secure Source Manager repository."
  value       = module.cicd_foundation.secure_source_manager_repository_git_https
}

output "vpc_dev_self_link" {
  description = "The URI of the dev VPC network."
  value       = module.vpc-dev.self_link
}

output "vpc_hub_self_link" {
  description = "The URI of the hub VPC network."
  value       = module.vpc-hub.self_link
}

output "vpc_prod_self_link" {
  description = "The URI of the prod VPC network."
  value       = module.vpc-prod.self_link
}

output "vpc_test_self_link" {
  description = "The URI of the test VPC network."
  value       = module.vpc-test.self_link
}
# go/keep-sorted end
