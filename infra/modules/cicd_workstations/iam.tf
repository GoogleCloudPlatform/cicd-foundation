# Copyright 2023-2026 Google LLC
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

locals {
  workstation_users = toset(flatten([for config in var.cws_configs : coalesce(config.creators, [])]))

  workstation_user_roles = toset([
    # go/keep-sorted start
    "roles/aiplatform.user",
    "roles/browser",
    "roles/cloudaicompanion.user",
    "roles/workstations.operationViewer",
    # go/keep-sorted end
  ])

  workstation_user_role_members = {
    for pair in flatten([
      for role in local.workstation_user_roles : [
        for user in local.workstation_users : {
          role = role
          user = user
        }
      ]
    ]) : "${pair.role}-${pair.user}" => pair
  }
}

module "cws_service_account" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  project_id   = data.google_project.project.project_id
  name         = var.cws_service_account_name
  display_name = "Cloud Workstation Service Account"
  description  = "Terraform-managed."
}

# Grant required project-level roles to all workstation users.
resource "google_project_iam_member" "workstation_user_roles" {
  for_each = local.workstation_user_role_members

  project = data.google_project.project.project_id
  role    = each.value.role
  member  = "user:${each.value.user}"
}

# Grant workstation users the ability to act as the workstation service account.
resource "google_service_account_iam_member" "cws_sa_user" {
  for_each = local.workstation_users

  service_account_id = "projects/${data.google_project.project.project_id}/serviceAccounts/${module.cws_service_account.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${each.key}"
}
