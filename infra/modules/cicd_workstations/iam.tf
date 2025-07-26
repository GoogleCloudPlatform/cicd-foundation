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

resource "google_project_iam_custom_role" "cws_image_build_runner" {
  count = local.create_image_build_resources ? 1 : 0

  project     = data.google_project.project.id
  role_id     = "cwsBuildRunner"
  title       = "Cloud Workstation Image Build Runner"
  description = "Terraform managed."
  permissions = [
    "cloudbuild.builds.create",
  ]
}

module "cws_image_build_runner_service_account" {
  count = local.create_image_build_resources ? 1 : 0

  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v36.0.1"

  project_id   = data.google_project.project.project_id
  name         = "workstation-image-build-runner"
  display_name = "Cloud Workstation Image Build Runner Service Account"
  description  = "Terraform-managed."
  iam_sa_roles = {
    (var.cloud_build_service_account_id) : [
      "roles/iam.serviceAccountUser",
    ]
  }
}

resource "google_project_iam_member" "cws_image_build_runner" {
  count = local.create_image_build_resources ? 1 : 0

  project = data.google_project.project.id
  role    = google_project_iam_custom_role.cws_image_build_runner[0].name
  member  = module.cws_image_build_runner_service_account[0].iam_email
}

module "cws_service_account" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v40.1.0"

  project_id   = data.google_project.project.project_id
  name         = var.cws_service_account_name
  display_name = "Cloud Workstation Service Account"
  description  = "Terraform-managed."
}
