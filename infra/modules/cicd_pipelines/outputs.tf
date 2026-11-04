# Copyright 2023-2025 Google LLC
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

# Secret Manager

output "webhook_trigger_secret_id" {
  description = "The ID of the webhook trigger secret."
  value       = local.source.ssm ? google_secret_manager_secret.webhook_trigger[0].id : null
}

output "webhook_trigger_secret_name" {
  description = "The name of the webhook trigger secret."
  value       = local.source.ssm ? google_secret_manager_secret.webhook_trigger[0].name : null
}

# Source Control (Secure Source Manager)

# go/keep-sorted start block=yes newline_separated=yes
output "secure_source_manager_instance_git_http" {
  description = "The Git HTTP URI of the created Secure Source Manager instance."
  value = local.source.ssm && !local.ssm_instance_is_provided ? (
    google_secure_source_manager_instance.cicd_foundation[0].host_config[0].git_http
  ) : null
}

output "secure_source_manager_instance_git_ssh" {
  description = "The Git SSH URI of the created Secure Source Manager instance."
  value = local.source.ssm && !local.ssm_instance_is_provided ? (
    google_secure_source_manager_instance.cicd_foundation[0].host_config[0].git_ssh
  ) : null
}

output "secure_source_manager_instance_html" {
  description = "The HTML hostname of the Secure Source Manager instance."
  value = local.source.ssm && !local.ssm_instance_is_provided ? (
    google_secure_source_manager_instance.cicd_foundation[0].host_config[0].html
  ) : null
}

output "secure_source_manager_instance_id" {
  description = "The ID of the Secure Source Manager instance."
  value       = local.ssm_instance_id
}

output "secure_source_manager_repository_git_html" {
  description = "The Git HTML URI of the created Secure Source Manager repository."
  value = local.source.ssm ? (
    google_secure_source_manager_repository.cicd_foundation[0].uris[0].html
  ) : null
}

output "secure_source_manager_repository_git_https" {
  description = "The Git HTTP URI of the created Secure Source Manager repository."
  value = local.source.ssm ? (
    google_secure_source_manager_repository.cicd_foundation[0].uris[0].git_https
  ) : null
}

output "secure_source_manager_repository_id" {
  description = "The full ID of the created Secure Source Manager repository resource."
  value = local.source.ssm ? (
    google_secure_source_manager_repository.cicd_foundation[0].id
  ) : null
}

output "secure_source_manager_repository_name" {
  description = "The short name (repository_id) of the created Secure Source Manager repository."
  value = local.source.ssm ? (
    google_secure_source_manager_repository.cicd_foundation[0].repository_id
  ) : null
}
# go/keep-sorted end

# Cloud Build

# go/keep-sorted start block=yes newline_separated=yes
output "cloud_build_api_key" {
  description = "The API key for Cloud Build webhook triggers."
  value       = local.source.ssm ? google_apikeys_key.cloud_build[0].key_string : null
  sensitive   = true
}

output "cloud_build_service_account_email" {
  description = "The email of the Cloud Build service account."
  value       = module.service_account_cloud_build.email
}

output "cloud_build_service_account_id" {
  description = "The ID of the Cloud Build service account."
  value       = module.service_account_cloud_build.id
}

output "cloud_build_trigger_github_connection_needed" {
  description = "Instructions to connect GitHub repository if using GitHub source."
  value = local.source.github ? (<<-EOT
    you first need to connect the GitHub repository to your GCP project:
    https://console.cloud.google.com/cloud-build/triggers;region=${var.cloud_build_region}/connect?project=${local.build_project_id}
    before you can create this trigger
  EOT
  ) : ""
}

output "cloud_build_trigger_id" {
  description = "The full resource ID of the Cloud Build trigger."
  value       = { for k, v in google_cloudbuild_trigger.ci_pipeline : k => v.id }
}

output "cloud_build_trigger_trigger_id" {
  description = "The unique short ID of the Cloud Build trigger."
  value       = { for k, v in google_cloudbuild_trigger.ci_pipeline : k => v.trigger_id }
}

output "cloud_build_worker_pool_ids" {
  description = "A map of Cloud Build Worker Pool IDs, keyed by stage name."
  value       = { for k, v in google_cloudbuild_worker_pool.pool : k => v.id }
}
# go/keep-sorted end

# Cloud Deploy

# go/keep-sorted start block=yes newline_separated=yes
output "cloud_deploy_service_account_emails" {
  description = "A map of Cloud Deploy execution service account emails, keyed by stage name."
  value       = { for k, v in module.service_account_cloud_deploy : k => v.email }
}
# go/keep-sorted end

# Binary Authorization

# go/keep-sorted start block=yes newline_separated=yes
output "binary_authorization_attestor_id" {
  description = "The ID of the created Binary Authorization Attestor."
  value       = local.create_binary_authorization_resources ? google_binary_authorization_attestor.vulnz_attestor[0].id : null
}

output "binary_authorization_policy_id" {
  description = "The ID of the created Binary Authorization Policy in the primary project."
  value       = try(google_binary_authorization_policy.policy[var.project_id].id, null)
}

output "binary_authorization_policy_ids" {
  description = "A map of Binary Authorization Policy IDs, keyed by GCP project ID."
  value       = { for k, v in google_binary_authorization_policy.policy : k => v.id }
}
# go/keep-sorted end

# Artifact Registry

# go/keep-sorted start block=yes newline_separated=yes
output "artifact_registry_repository" {
  description = "The Artifact Registry repository object."
  value       = data.google_artifact_registry_repository.container_repository
}

output "artifact_registry_repository_uri" {
  description = "The URI of the Artifact Registry repository."
  value       = local.artifact_registry_repository_uri
}
# go/keep-sorted end

# Cloud Workstations

# go/keep-sorted start block=yes newline_separated=yes
output "cws_image_build_runner_service_account_email" {
  description = "The email of the Cloud Workstation Image Build Runner service account."
  value = length(local.scheduled_apps) > 0 ? (
    module.cws_image_build_runner_service_account[0].email
  ) : null
}

output "cws_image_build_runner_service_account_id" {
  description = "The ID of the Cloud Workstation Image Build Runner service account."
  value = length(local.scheduled_apps) > 0 ? (
    module.cws_image_build_runner_service_account[0].id
  ) : null
}
# go/keep-sorted end
