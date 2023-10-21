# Copyright 2023 Google LLC
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
  shared_vpc_service_config = var.project_hub_id != var.project_service_id ? {
    host_project = var.project_hub_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  } : null
}

module "project_service" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v24.0.0"
  name           = var.project_service_id
  project_create = false
  services       = var.project_service_services
  shared_vpc_service_config = local.shared_vpc_service_config
  iam = {
    "roles/containeranalysis.occurrences.editor" = [
      "serviceAccount:${var.sa-cb-email}"
    ]
  }
}

data "google_project" "hub" {
  project_id = var.project_hub_id
}

data "google_project" "service" {
  project_id = var.project_service_id
}

resource "google_project_iam_member" "binauthz-deployer" {
  project = data.google_project.hub.project_id
  role    = "roles/binaryauthorization.attestorsVerifier"
  member  = "serviceAccount:service-${data.google_project.service.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}
