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

locals {
  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "workstations.googleapis.com",
  ]
  default_labels = {
    "tf_module_github_org"  = "GoogleCloudPlatform"
    "tf_module_github_repo" = "cicd-foundation"
    "tf_module_name"        = "cicd_workstations"
    "tf_module_version"     = "v8-0-0"
  }
  # merge the default labels with the user-provided labels and convert to lowercase
  common_labels = {
    for k, v in merge(var.labels, local.default_labels) : lower(k) => lower(v)
  }
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project_services
  ]
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.2.0"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = false
  activate_apis               = local.activate_apis
}
