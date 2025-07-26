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

locals {
  images       = keys(var.apps)
  target_names = keys(var.aosp_targets)

  ws_configs = {
    for item in setproduct(local.images, var.aosp_branches, local.target_names) :
    "${lower(item[0])}-${lower(item[1])}-${lower(item[2])}" => {
      # max 63 chars
      name = "${lower(item[1])}-${lower(item[2])}"

      image  = item[0]
      branch = item[1]
      target = var.aosp_targets[item[2]]
      app    = var.apps[item[0]]
    } if var.apps[item[0]].runtime == "workstation"
  }
}

module "project" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v36.0.1"
  name           = var.project_id
  project_create = false
  services       = var.project_services
  shared_vpc_host_config = {
    enabled = false
  }
}

resource "google_project_iam_member" "workstations_operation_viewer" {
  count   = length(var.admins)
  project = module.project.id
  role    = "roles/workstations.operationViewer"
  member  = "user:${var.admins[count.index]}"
}
