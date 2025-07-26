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

module "repo" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/source-repository?ref=v36.0.1"
  for_each   = var.github_owner != "" && var.github_repo != "" ? {} : { "CSR" : true }
  project_id = var.project_id
  name       = var.repo_name
  iam = {
    "roles/source.writer" = [for user in var.admins : "user:${user}"]
  }
}

# resource "google_secure_source_manager_instance" "source" {
#   project     = module.project.id
#   location    = var.region
#   instance_id = var.ssm_instance_name
# }

# resource "random_id" "random" {
#   # one byte is represented by 2 hex
#   byte_length = 64
# }

# resource "google_secret_manager_secret" "webhook_trigger" {
#   project   = module.project.id
#   secret_id = "webhook-trigger"
#   replication {
#     user_managed {
#       replicas {
#         location = var.region
#       }
#     }
#   }
# }

# resource "google_secret_manager_secret_version" "webhook_trigger" {
#   secret      = google_secret_manager_secret.webhook_trigger.id
#   secret_data = random_id.random.hex
# }

# data "google_iam_policy" "secret_accessor" {
#   binding {
#     role = "roles/secretmanager.secretAccessor"
#     members = [
#       "serviceAccount:service-${module.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
#     ]
#   }
# }

# resource "google_secret_manager_secret_iam_policy" "policy" {
#   project     = google_secret_manager_secret.webhook_trigger.project
#   secret_id   = google_secret_manager_secret.webhook_trigger.secret_id
#   policy_data = data.google_iam_policy.secret_accessor.policy_data
# }

# resource "google_secure_source_manager_repository" "repo" {
#   project       = var.project_id
#   location      = var.region
#   repository_id = var.repo_name
#   instance      = var.ssm_instance_name

#   description = "Terraform-managed."
#   initial_config {
#     default_branch = var.git_branch
#   }
# }

# resource "google_secure_source_manager_repository_iam_binding" "repo_writer" {
#   project       = google_secure_source_manager_repository.repo.project
#   location      = google_secure_source_manager_repository.repo.location
#   repository_id = google_secure_source_manager_repository.repo.repository_id
#   role          = "roles/securesourcemanager.repoWriter"
#   members       = [for user in var.admins : "user:${user}"]
# }
