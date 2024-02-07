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

resource "google_cloudbuild_trigger" "hello_world" {
  provider        = google-beta
  name            = "${var.team_prefix}-hello-world"
  project         = var.project_id
  location        = var.region
  service_account = var.sa-cb-id
  description     = "Terraform-managed."
  filename        = "cicd/cloudbuild/skaffold+kritis.yaml"
  dynamic "github" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [1] : []
    content {
      # you first need to connect the GitHub repository to your GCP project:
      # https://console.cloud.google.com/cloud-build/triggers;region=global/connect
      # before you can create this trigger
      owner = var.github_owner
      name  = var.github_repo
      push {
        branch = var.git_branch
      }
    }
  }
  dynamic "trigger_template" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
    content {
      branch_name = var.git_branch
      repo_name   = module.repo.name
    }
  }
  included_files = [
    "apps/hello-world/**"
  ]
  substitutions = {
    _APP_NAME              = "hello-world"
    _KMS_DIGEST_ALG        = var.kms_digest_alg
    _KMS_KEY_NAME          = var.kms_key_name
    _KRITIS_SIGNER_IMAGE   = var.kritis_signer_image
    _NAMESPACE             = var.team_prefix
    _NOTE_NAME             = var.kritis_note
    _PIPELINE_NAME         = "${google_clouddeploy_delivery_pipeline.hello_world.name}"
    _REGION                = "${var.region}"
    _SKAFFOLD_DEFAULT_REPO = "${var.region}-docker.pkg.dev/${var.project_id}/${module.docker_artifact_registry.name}"
  }
}

resource "google_clouddeploy_delivery_pipeline" "hello_world" {
  project     = var.project_id
  location    = var.region
  name        = "${var.team_prefix}-hello-world"
  description = "Terraform-managed."
  serial_pipeline {
    stages {
      profiles  = ["dev"]
      target_id = var.cd_target_dev
    }
    stages {
      profiles  = ["test"]
      target_id = var.cd_target_test
    }
    stages {
      profiles  = ["prod"]
      target_id = var.cd_target_prod
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
