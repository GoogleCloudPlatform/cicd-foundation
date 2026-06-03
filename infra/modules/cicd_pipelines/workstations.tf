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

# Fetch an existing custom role for the Cloud Workstations image build runner.
# This role is not namespaced and is reused.
data "google_project_iam_custom_role" "cws_image_build_runner_data" {
  count = length(local.workstation_apps) > 0 && ! var.cws_image_build_runner_role_create ? 1 : 0

  project = data.google_project.project.project_id
  role_id = var.cws_image_build_runner_role_id
}

# Create a custom role for the Cloud Workstations image build runner.
# This role is not namespaced.
resource "google_project_iam_custom_role" "cws_image_build_runner" {
  count = length(local.workstation_apps) > 0 && var.cws_image_build_runner_role_create ? 1 : 0

  project     = data.google_project.project.project_id
  role_id     = var.cws_image_build_runner_role_id
  title       = var.cws_image_build_runner_role_title
  description = "Terraform managed."
  permissions = [
    "cloudbuild.builds.create",
  ]
}

module "cws_image_build_runner_service_account" {
  count = length(local.workstation_apps) > 0 ? 1 : 0

  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  project_id   = data.google_project.project.project_id
  name         = "${local.prefix}cws-image-builder"
  display_name = "Cloud Workstation Image Build Runner Service Account"
  description  = "Terraform-managed."
  iam_sa_roles = {
    (module.service_account_cloud_build.id) : [
      "roles/iam.serviceAccountUser",
    ]
  }
}

resource "google_project_iam_member" "cws_image_build_runner" {
  count = length(local.workstation_apps) > 0 ? 1 : 0

  project = data.google_project.project.project_id
  role = (
    var.cws_image_build_runner_role_create
    ? google_project_iam_custom_role.cws_image_build_runner[0].name
    : data.google_project_iam_custom_role.cws_image_build_runner_data[0].name
  )
  member = module.cws_image_build_runner_service_account[0].iam_email
}

# Cloud Scheduler

# cf. https://cloud.google.com/workstations/docs/tutorial-automate-container-image-rebuild
resource "google_cloud_scheduler_job" "cws_image_rebuild" {
  for_each = local.workstation_apps

  project     = data.google_project.project.project_id
  region      = coalesce(try(each.value.workstation_config.scheduler_region, null), var.scheduler_default_region)
  name        = "${local.prefix}${each.key}-cws-image-rebuild"
  description = "Terraform-managed."
  schedule    = coalesce(try(each.value.workstation_config.ci_schedule, null), var.default_ci_schedule)
  paused      = try(each.value.workstation_config.paused, false)
  # cf. https://cloud.google.com/build/docs/api/reference/rest/v1/projects.triggers/run
  http_target {
    http_method = "POST"
    uri = format("https://cloudbuild.googleapis.com/v1/projects/%s/locations/%s/triggers/%s:run",
      data.google_project.project.project_id,
      var.cloud_build_region,
      google_cloudbuild_trigger.ci_pipeline[local.app_source[each.key].has_github ? "${each.key}-manual" : each.key].name
    )
    oauth_token {
      service_account_email = module.cws_image_build_runner_service_account[0].email
    }
  }
}
