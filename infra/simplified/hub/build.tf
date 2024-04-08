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

# cf. https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts
module "sa-cb" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v29.0.0"
  project_id   = var.project_id
  name         = var.sa_cb_name
  display_name = "Cloud Build Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) : [
      "roles/cloudbuild.builds.builder",
      "roles/clouddeploy.releaser",
      "roles/containeranalysis.notes.occurrences.viewer",
      "roles/containeranalysis.occurrences.viewer",
    ],
  }
}

# preparing for Secure Source Manager
# resource "google_secure_source_manager_instance" "ssm" {
#   project     = var.project_id
#   location    = var.region
#   instance_id = "ssm"
# }

# resource "google_secure_source_manager_instance_iam_member" "ssm" {
#   count       = length(var.developers)
#   project     = google_secure_source_manager_instance.ssm.project
#   location    = google_secure_source_manager_instance.ssm.location
#   instance_id = google_secure_source_manager_instance.ssm.instance_id
#   role        = "roles/securesourcemanager.instanceRepositoryCreator"
#   member      = var.developers[count.index]
# }
