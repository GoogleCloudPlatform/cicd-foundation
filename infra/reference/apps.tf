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

resource "google_cloudbuild_trigger" "continuous-integration" {
  count           = length(var.apps)
  provider        = google-beta
  name            = var.apps[count.index]
  project         = module.project_hub_supplychain.id
  location        = var.region
  service_account = module.sa-cb.id
  description     = "Terraform-managed."
  build {
    step {
      id   = "build"
      dir  = "apps/$${_APP_NAME}"
      name = "gcr.io/k8s-skaffold/skaffold:$${_SKAFFOLD_IMAGE_TAG}"
      args = [
        "skaffold",
        "build",
        "--interactive=false",
        "--default-repo=$${_SKAFFOLD_DEFAULT_REPO}",
      ]
    }
    step {
      id         = "fetchImageDigest"
      wait_for   = ["build"]
      dir        = "apps/$${_APP_NAME}"
      name       = "gcr.io/cloud-builders/docker:$${_DOCKER_IMAGE_TAG}"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        "docker pull $${_SKAFFOLD_DEFAULT_REPO}/$${_APP_NAME}:$${SHORT_SHA} && docker image inspect $${_SKAFFOLD_DEFAULT_REPO}/$${_APP_NAME}:$${SHORT_SHA} --format '{{index .RepoDigests 0}}' > image-digest.txt",
      ]
    }
    step {
      id         = "vulnsign"
      wait_for   = ["fetchImageDigest"]
      name       = "$_KRITIS_SIGNER_IMAGE"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        "/kritis/signer -v=10 -alsologtostderr -image=$$(/bin/cat ./apps/$${_APP_NAME}/image-digest.txt) -policy=./tools/kritis/vulnz-signing-policy.yaml -kms_key_name=$${_KMS_KEY_NAME} -kms_digest_alg=$${_KMS_DIGEST_ALG} -note_name=$${_NOTE_NAME} || true",
      ]
    }
    step {
      id         = "createRelease"
      wait_for   = ["vulnsign"]
      dir        = "apps/$${_APP_NAME}"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk:$${_GCLOUD_IMAGE_TAG}"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        "gcloud deploy releases create rel-$${SHORT_SHA} --delivery-pipeline=$${_PIPELINE_NAME} --labels=commit-sha=$COMMIT_SHA,commit-short-sha=$SHORT_SHA,commitId=$REVISION_ID,gcb-build-id=$BUILD_ID --annotations=commit-sha=$COMMIT_SHA,commit-short-sha=$SHORT_SHA,commitId=$REVISION_ID,gcb-build-id=$BUILD_ID --region=$${_REGION} --deploy-parameters=commit-sha=$COMMIT_SHA,commit-short-sha=$SHORT_SHA,commitId=$REVISION_ID,gcb-build-id=$BUILD_ID,namespace=$${_NAMESPACE},deploy_replicas=$${_REPLICAS} --images=$${_APP_NAME}=$(/bin/cat image-digest.txt)",
      ]
    }
    images = [
      "$${_SKAFFOLD_DEFAULT_REPO}/$${_APP_NAME}:$${SHORT_SHA}"
    ]
    options {
      requested_verify_option = "VERIFIED"
      logging                 = "CLOUD_LOGGING_ONLY"
    }
  }
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
    "apps/${var.apps[count.index]}/**"
  ]
  substitutions = {
    _APP_NAME              = var.apps[count.index]
    _DOCKER_IMAGE_TAG      = var.docker_image_tag
    _GCLOUD_IMAGE_TAG      = var.gcloud_image_tag
    _KMS_DIGEST_ALG        = var.kms_digest_alg
    _KMS_KEY_NAME          = var.kms_key_name
    _KRITIS_SIGNER_IMAGE   = var.kritis_signer_image
    _NAMESPACE             = var.apps[count.index]
    _NOTE_NAME             = google_container_analysis_note.vulnz-attestor.id
    _PIPELINE_NAME         = "${google_clouddeploy_delivery_pipeline.continuous-delivery[count.index].name}"
    _REGION                = "${var.region}"
    _REPLICAS              = var.deploy_replicas
    _SKAFFOLD_DEFAULT_REPO = "${var.region}-docker.pkg.dev/${module.project_hub_supplychain.project_id}/${module.docker_artifact_registry.name}"
    _SKAFFOLD_IMAGE_TAG    = var.skaffold_image_tag
  }
}

resource "google_clouddeploy_delivery_pipeline" "continuous-delivery" {
  count       = length(var.apps)
  project     = module.project_hub_supplychain.id
  name        = var.apps[count.index]
  description = "Terraform-managed."
  location    = var.region
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
                deployment             = var.apps[count.index]
                http_route             = var.apps[count.index]
                route_update_wait_time = "120s"
                service                = var.apps[count.index]
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

resource "google_clouddeploy_automation" "promote-release" {
  count             = length(var.apps)
  name              = var.apps[count.index]
  project           = google_clouddeploy_delivery_pipeline.continuous-delivery[count.index].project
  location          = google_clouddeploy_delivery_pipeline.continuous-delivery[count.index].location
  delivery_pipeline = google_clouddeploy_delivery_pipeline.continuous-delivery[count.index].name
  description       = "Terraform-managed."
  service_account   = module.sa-cb.email
  selector {
    targets {
      id = "*"
    }
  }
  suspended = false
  rules {
    promote_release_rule {
      id = "promote-release"
    }
  }
}
