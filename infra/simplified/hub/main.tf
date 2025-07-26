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

module "project" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.0.0"
  name           = var.project_id
  project_create = false
  services       = var.project_services
  shared_vpc_host_config = {
    enabled = false
  }
  iam = {
    "roles/binaryauthorization.policyViewer" = var.developers,
    "roles/cloudbuild.builds.editor"         = var.developers,
    "roles/clouddeploy.approver"             = var.developers,
    "roles/clouddeploy.viewer"               = var.developers,
    "roles/containeranalysis.notes.attacher" = [module.sa-cb.iam_email],
    "roles/workstations.operationViewer"     = var.developers,
  }
}

resource "google_project_iam_member" "artifact_registry_reader" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/artifactregistry.reader"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "browser" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/browser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "occurrences_viewer" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "container_developer" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/container.developer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "run_developer" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/run.developer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "deploy_jobrunner" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/clouddeploy.jobRunner"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "deploy_releaser" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/clouddeploy.releaser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "logging_viewer" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/logging.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "monitoring_viewer" {
  count   = length(var.developers)
  project = module.project.id
  role    = "roles/monitoring.viewer"
  member  = var.developers[count.index]
}
