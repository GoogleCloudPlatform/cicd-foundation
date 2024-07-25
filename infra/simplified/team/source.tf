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

resource "google_secure_source_manager_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.team
  instance      = var.ssm_instance_name

  description = "Terraform-managed."
  initial_config {
    default_branch = "main"
  }
}

resource "google_secure_source_manager_repository_iam_binding" "repo_writer" {
  project       = google_secure_source_manager_repository.repo.project
  location      = google_secure_source_manager_repository.repo.location
  repository_id = google_secure_source_manager_repository.repo.repository_id
  role          = "roles/securesourcemanager.repoWriter"
  members = [
    "user:${var.user_identity}",
  ]
}
