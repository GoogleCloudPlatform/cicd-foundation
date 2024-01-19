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

# you first need to connect the GitHub repository to your GCP project:
# https://console.cloud.google.com/cloud-build/triggers;region=global/connect
# before you can create this trigger
resource "google_cloudbuild_trigger" "hello_world" {
  provider        = google-beta
  name            = "${var.team-prefix}-hello-world"
  project         = var.project_id
  service_account = var.sa-cb-id
  description     = "Terraform-managed."
  filename        = "cloudbuild.yaml"
  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = var.github_branch
    }
  }
  included_files = [
    "apps/hello-world/**"
  ]
  substitutions = {
    _APP_NAME              = "hello-world"
    _KMS_DIGEST_ALG        = var.kms_digest_alg
    _KMS_KEY_NAME          = data.google_kms_crypto_key_version.vulnz-attestor.name
    _KRITIS_SIGNER_IMAGE   = var.kritis_signer_image
    _NOTE_NAME             = google_container_analysis_note.vulnz-attestor.id
    _PIPELINE_NAME         = "${google_clouddeploy_delivery_pipeline.hello_world.name}"
    _REGION                = "${var.region}"
    _SKAFFOLD_DEFAULT_REPO = "${var.region}-docker.pkg.dev/${var.project_id}/${module.docker_artifact_registry.name}"
  }
}

resource "google_clouddeploy_delivery_pipeline" "hello_world" {
  project     = var.project_id
  location    = var.region
  name        = "${var.team-prefix}-hello-world"
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
      strategy {
        canary {
          runtime_config {
            kubernetes {
              gateway_service_mesh {
                deployment             = "hello-world"
                http_route             = "hello-world"
                route_update_wait_time = "120s"
                service                = "hello-world"
              }
            }
          }
          canary_deployment {
            percentages = [10, 25, 50]
            verify      = false # could execute smoke tests to verify canary deployment
          }
        }
      }
    }
  }
}
