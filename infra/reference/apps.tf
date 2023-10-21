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

# you first need to connect the GitHub repository to your GCP project:
# https://console.cloud.google.com/cloud-build/triggers;region=global/connect
# before you can create this trigger
resource "google_cloudbuild_trigger" "hello_world" {
  provider        = google-beta
  project         = module.project_hub_supplychain.id
  service_account = module.sa-cb.id
  description     = "Terraform-managed."
  filename        = "cloudbuild.yaml"
  github {
    owner = var.github_owner
    name  = var.github_repo_name
    push {
      branch = var.github_branch
    }
  }
  included_files = [
    "apps/${google_clouddeploy_delivery_pipeline.hello_world.name}/**"
  ]
  substitutions = {
    _REGION                = "${var.region}"
    _SKAFFOLD_DEFAULT_REPO = "${var.region}-docker.pkg.dev/${module.project_hub_supplychain.project_id}/${module.docker_artifact_registry.name}"
    _APP_NAME              = "${google_clouddeploy_delivery_pipeline.hello_world.name}"
  }
}

resource "google_clouddeploy_delivery_pipeline" "hello_world" {
  project     = module.project_hub_supplychain.id
  location    = var.region
  name        = "hello-world"
  description = "Terraform-managed."
  serial_pipeline {
    stages {
      profiles  = ["dev"]
      target_id = google_clouddeploy_target.cluster-dev.name
    }
    stages {
      profiles  = ["test"]
      target_id = google_clouddeploy_target.cluster-test.name
    }
    stages {
      profiles  = ["prod"]
      target_id = google_clouddeploy_target.cluster-prod.name
    }
  }
}
