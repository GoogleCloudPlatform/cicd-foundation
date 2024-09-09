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
  for_each        = var.apps
  provider        = google-beta
  name            = each.key
  project         = module.project_hub_supplychain.id
  location        = var.region
  service_account = module.sa-cb.id
  description     = "Terraform-managed."
  dynamic "github" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [1] : []
    content {
      # you first need to connect the GitHub repository to your GCP project:
      # https://console.cloud.google.com/cloud-build/triggers;region=global/connect
      # before you can create this trigger
      owner = var.github_owner
      name  = var.github_repo
      push {
        branch = var.git_branch_trigger_regexp
      }
    }
  }
  dynamic "webhook_config" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
    content {
      secret = google_secret_manager_secret_version.webhook_trigger.secret
    }
  }
  dynamic "source_to_build" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
    content {
      uri       = google_secure_source_manager_repository.repo.name
      ref       = "refs/heads/${var.git_branch_trigger}"
      repo_type = "UNKNOWN"
    }
  }
  build {
    step {
      id   = "build"
      dir  = "apps/$${_APP_NAME}"
      name = "gcr.io/k8s-skaffold/skaffold:$${_SKAFFOLD_IMAGE_TAG}"
      args = [
        "skaffold",
        "build",
        "--default-repo=$${_SKAFFOLD_DEFAULT_REPO}",
        "--interactive=false",
        "--file-output=$${_SKAFFOLD_OUTPUT}",
        "--quiet=$${_SKAFFOLD_QUIET}",
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
        join(" ", [
          "/bin/grep",
          "-Po",
          "'\"tag\":\"\\K[^\"]*'",
          "$${_SKAFFOLD_OUTPUT}",
          ">",
          "images.txt",
          ";",
          "IMAGES=$$(/bin/cat images.txt)",
          ";",
          "for IMAGE in $$IMAGES",
          ";",
          "do",
          "IMAGE_NAME=$$(/bin/echo \"$$IMAGE\" | /bin/sed 's/\\([^:]*\\).*/\\1/')",
          ";",
          "DIGEST_FILENAME=$$(/bin/echo \"$$IMAGE\" | /bin/sed 's/.*@sha256://').digest",
          ";",
          "docker",
          "pull",
          "$$IMAGE",
          "&&",
          "docker",
          "tag",
          "$$IMAGE",
          "$$IMAGE_NAME:latest",
          "&&",
          "docker",
          "push",
          "$$IMAGE_NAME:latest",
          "&&",
          "docker",
          "image",
          "inspect",
          "$$IMAGE",
          "--format='{{index .RepoDigests 0}}'",
          ">",
          "$$DIGEST_FILENAME",
          ";",
          "done",
          ]
        )
      ]
      allow_failure = true
    }
    step {
      id         = "vulnsign"
      wait_for   = ["fetchImageDigest"]
      name       = "$_KRITIS_SIGNER_IMAGE"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        join(" ", [
          "IMAGES=$$(/bin/cat ./apps/$${_APP_NAME}/images.txt)",
          ";",
          "for IMAGE in $$IMAGES",
          ";",
          "do",
          "DIGEST_FILENAME=$$(/bin/echo \"$$IMAGE\" | /bin/sed 's/.*@sha256://').digest",
          ";",
          "/kritis/signer",
          "-v=10",
          "-alsologtostderr",
          "-image=$$(/bin/cat ./apps/$${_APP_NAME}/$$DIGEST_FILENAME)",
          "-policy=$${_POLICY_FILE}",
          "-kms_key_name=$${_KMS_KEY_NAME}",
          "-kms_digest_alg=$${_KMS_DIGEST_ALG}",
          "-note_name=$${_NOTE_NAME}",
          ";",
          "done",
          ]
        )
      ]
      allow_failure = true
    }
    step {
      id         = "createRelease"
      wait_for   = ["vulnsign"]
      dir        = "apps/$${_APP_NAME}"
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk:$${_GCLOUD_IMAGE_TAG}"
      entrypoint = "/bin/sh"
      args = [
        "-c",
        join(" ", [
          "gcloud",
          "deploy",
          "releases",
          "create",
          "rel-$${SHORT_SHA}",
          "--delivery-pipeline=$${_PIPELINE_NAME}",
          "--build-artifacts=$${_SKAFFOLD_OUTPUT}",
          join(",", [
            "--labels=commit-sha=$COMMIT_SHA",
            "commit-short-sha=$SHORT_SHA",
            "commitId=$REVISION_ID",
            "gcb-build-id=$BUILD_ID",
            ]
          ),
          join(",", [
            "--annotations=commit-sha=$COMMIT_SHA",
            "commit-short-sha=$SHORT_SHA",
            "commitId=$REVISION_ID",
            "gcb-build-id=$BUILD_ID",
            ]
          ),
          "--region=$${_REGION}",
          join(",", [
            "--deploy-parameters=commit-sha=$COMMIT_SHA",
            "commit-short-sha=$SHORT_SHA",
            "commitId=$REVISION_ID",
            "gcb-build-id=$BUILD_ID",
            "namespace=$${_NAMESPACE}",
            ]
          ),
          ]
        )
      ]
    }
    timeout = each.value.build != null ? "${each.value.build.timeout}s" : "${var.build_timeout_default}s"
    options {
      requested_verify_option = "VERIFIED"
      logging                 = "CLOUD_LOGGING_ONLY"
      machine_type            = each.value.build != null ? each.value.build.machine_type : var.build_machine_type_default
    }
  }
  included_files = [
    "apps/${each.key}/**"
  ]
  substitutions = {
    _APP_NAME              = each.key
    _DOCKER_IMAGE_TAG      = var.docker_image_tag
    _GCLOUD_IMAGE_TAG      = var.gcloud_image_tag
    _KMS_DIGEST_ALG        = var.kms_digest_alg
    _KMS_KEY_NAME          = var.kms_key_name
    _KRITIS_SIGNER_IMAGE   = var.kritis_signer_image
    _NAMESPACE             = each.key
    _NOTE_NAME             = google_container_analysis_note.vulnz-attestor.id
    _PIPELINE_NAME         = google_clouddeploy_delivery_pipeline.continuous-delivery[each.key].name
    _POLICY_FILE           = var.policy_file
    _REGION                = var.region
    _SKAFFOLD_DEFAULT_REPO = module.docker_artifact_registry.url
    _SKAFFOLD_IMAGE_TAG    = var.skaffold_image_tag
    _SKAFFOLD_OUTPUT       = var.skaffold_output
    _SKAFFOLD_QUIET        = var.skaffold_quiet
  }
}

resource "google_clouddeploy_delivery_pipeline" "continuous-delivery" {
  for_each    = var.apps
  project     = module.project_hub_supplychain.id
  location    = var.region
  name        = each.key
  description = "Terraform-managed."
  serial_pipeline {
    dynamic "stages" {
      for_each = var.stages
      content {
        profiles  = [stages.value]
        target_id = each.value.runtime == "gke" ? "cluster-${stages.value}" : "run-${stages.value}"
        dynamic "deploy_parameters" {
          for_each = each.value.stages[stages.value]
          content {
            values = {
              "ENV"                      = "${stages.value}"
              "${deploy_parameters.key}" = "${deploy_parameters.value}"
            }
          }
        }
        dynamic "strategy" {
          for_each = stages.value == "prod" && each.value.runtime == "gke" ? [1] : []
          content {
            canary {
              runtime_config {
                kubernetes {
                  gateway_service_mesh {
                    deployment             = each.key
                    http_route             = each.key
                    route_update_wait_time = "120s"
                    service                = each.key
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
  }
}

resource "google_clouddeploy_automation" "promote-release" {
  for_each          = var.apps
  name              = each.key
  project           = google_clouddeploy_delivery_pipeline.continuous-delivery[each.key].project
  location          = google_clouddeploy_delivery_pipeline.continuous-delivery[each.key].location
  delivery_pipeline = google_clouddeploy_delivery_pipeline.continuous-delivery[each.key].name
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
