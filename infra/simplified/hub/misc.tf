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

module "sa-demo-prod" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "sa-demo-prod"
  display_name = "Service Account for demo applications in PROD"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) : [
    ],
  }
}

resource "google_service_account_iam_binding" "sa-demo-prod-iam" {
  service_account_id = module.sa-demo-prod.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    module.sa-cd-prod.iam_email,
  ]
}

module "sa-demo-test" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "sa-demo-test"
  display_name = "Service Account for demo applications in TEST"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) : [
    ],
  }
}

resource "google_service_account_iam_binding" "sa-demo-test-iam" {
  service_account_id = module.sa-demo-test.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    module.sa-cd-test.iam_email,
  ]
}

module "sa-demo-dev" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = var.project_id
  name         = "sa-demo-dev"
  display_name = "Service Account for demo applications in DEV"
  description  = "Terraform-managed."
  iam_project_roles = {
    (var.project_id) : [
    ],
  }
}

resource "google_service_account_iam_binding" "sa-demo-dev-iam" {
  service_account_id = module.sa-demo-dev.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    module.sa-cd-dev.iam_email,
  ]
}
