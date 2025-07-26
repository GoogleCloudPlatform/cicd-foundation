# Copyright 2024-2025 Google LLC
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
  project         = var.project_id
  location        = var.region
  service_account = module.sa-cb.id
  description     = "Terraform-managed."
  # for GitHub
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
  # for Cloud Source Repository (CSR)
  dynamic "trigger_template" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
    content {
      branch_name = var.git_branch_trigger_regexp
      repo_name   = var.repo_name
    }
  }
  # for Secure Source Manager (SSM)
  # dynamic "webhook_config" {
  #   for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
  #   content {
  #     secret = var.webhook_trigger_secret
  #   }
  # }
  dynamic "source_to_build" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [1] : []
    content {
      uri       = "https://github.com/${var.github_owner}/${var.github_repo}.git"
      ref       = "refs/heads/${var.git_branch_trigger}"
      repo_type = "GITHUB"
    }
  }
  dynamic "source_to_build" {
    for_each = var.github_owner != "" && var.github_repo != "" ? [] : [1]
    content {
      uri       = module.repo["CSR"].url
      ref       = "refs/heads/${var.git_branch_trigger}"
      repo_type = "CLOUD_SOURCE_REPOSITORIES"
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
    _SKAFFOLD_DEFAULT_REPO = module.docker_artifact_registry.url
    _SKAFFOLD_IMAGE_TAG    = var.skaffold_image_tag
    _SKAFFOLD_OUTPUT       = var.skaffold_output
    _SKAFFOLD_QUIET        = var.skaffold_quiet
  }
}
