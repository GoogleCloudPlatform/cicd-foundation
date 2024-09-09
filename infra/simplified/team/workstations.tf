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

resource "google_workstations_workstation" "cicd_foundation" {
  provider               = google-beta
  project                = var.project_id
  workstation_id         = var.team
  workstation_config_id  = var.ws_config_id
  workstation_cluster_id = var.ws_cluster_id
  location               = var.region
}

data "google_iam_policy" "workstations_user" {
  provider = google-beta
  binding {
    role    = "roles/workstations.user"
    members = ["user:${var.user_identity}"]
  }
}

resource "google_workstations_workstation_iam_policy" "policy" {
  provider               = google-beta
  project                = var.project_id
  location               = google_workstations_workstation.cicd_foundation.location
  workstation_cluster_id = google_workstations_workstation.cicd_foundation.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation.cicd_foundation.workstation_config_id
  workstation_id         = google_workstations_workstation.cicd_foundation.workstation_id
  policy_data            = data.google_iam_policy.workstations_user.policy_data
}
