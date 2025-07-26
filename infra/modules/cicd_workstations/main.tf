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
  create_image_build_resources = length(var.custom_images) > 0
  default_apis = [
    "compute.googleapis.com",
    "workstations.googleapis.com",
  ]
  activate_apis = concat(
    local.default_apis,
    local.create_image_build_resources ? ["cloudscheduler.googleapis.com"] : [],
  )
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project_services
  ]
}

module "project_services_cloud_resourcemanager" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.0.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "cloudresourcemanager.googleapis.com"
  ]
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.0.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis               = local.activate_apis

  depends_on = [
    module.project_services_cloud_resourcemanager
  ]
}
