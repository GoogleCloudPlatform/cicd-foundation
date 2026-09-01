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
  # go/keep-sorted start block=yes newline_separated=yes
  app_skaffold_paths = {
    for name, config in var.apps : name => coalesce(try(config.build.skaffold_path, null), "${var.apps_directory}/${name}")
  }

  # Build specifications for each combination in ci_apps.
  # Defines the build steps, timeout, and options based on the application and source type.
  ci_build_specs = {
    for app_source_key, app_source_config in local.ci_apps : app_source_key => {
      name         = app_source_config.name
      config       = app_source_config.config
      trigger_type = app_source_config.trigger_type
      postfix      = app_source_config.trigger_type == "github" || app_source_config.trigger_type == "manual" ? "-${app_source_config.trigger_type}" : ""
      steps = concat(
        (local.ci_apps_flags[app_source_key].needs_clone_step) ? [
          # Clones the source repository into the workspace.
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "clone"
            name          = "gcr.io/cloud-builders/git"
            wait_for      = []
            allow_failure = false
            dir           = null
            entrypoint    = "/bin/sh"
            args = [
              "-c",
              file("${path.module}/scripts/clone.sh.template")
            ]
            env = []
            # go/keep-sorted end
          }
        ] : [],
        try(app_source_config.config.agents["pre-build"]["review"].enabled, false) ? [
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "agentic-pre-build-review"
            name          = local.ci_runner_image
            wait_for      = (local.ci_apps_flags[app_source_key].needs_clone_step) ? ["clone"] : []
            allow_failure = try(app_source_config.config.agents["pre-build"]["review"].allow_failure, true)
            dir           = null
            entrypoint    = "/usr/bin/python3"
            args = [
              "infra/modules/cicd_pipelines/scripts/agentic_runner.py"
            ]
            env = [
              "GCP_PROJECT=${data.google_project.project.project_id}",
              "GCP_LOCATION=${var.deploy_region}",
              "MODEL_LOCATION=${coalesce(try(app_source_config.config.agents["pre-build"]["review"].location, null), var.default_agentic_location)}",
              "GOOGLE_API_USE_CLIENT_CERTIFICATE=false",
              "SKAFFOLD_PATH=${local.app_skaffold_paths[app_source_config.name]}",
              "AGENT_MODEL=${coalesce(try(app_source_config.config.agents["pre-build"]["review"].model, null), var.default_agentic_model)}",
              "AGENT_PERSONAS=${join(" ", coalesce(try(app_source_config.config.agents["pre-build"]["review"].personas, null), var.default_agentic_personas))}",
              "AGENT_PROMPT=${coalesce(try(app_source_config.config.agents["pre-build"]["review"].prompt, null), var.default_agentic_prompt)}",
              "AGENT_INSTRUCTIONS=${coalesce(try(app_source_config.config.agents["pre-build"]["review"].instructions, null), var.default_agentic_instructions)}"
            ]
            secret_env = []
            # go/keep-sorted end
          }
        ] : [],
        [
          # Builds the application images using Skaffold.
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "build"
            name          = local.ci_runner_image
            wait_for      = (try(app_source_config.config.agents["pre-build"]["review"].enabled, false)) ? ["agentic-pre-build-review"] : ((local.ci_apps_flags[app_source_key].needs_clone_step) ? ["clone"] : [])
            allow_failure = false
            dir           = local.app_skaffold_paths[app_source_config.name]
            entrypoint    = "/bin/sh"
            args = [
              "-c",
              file("${path.module}/scripts/build.sh.template")
            ]
            env = [
              for k, v in try(app_source_config.config.build.env, {}) : "${k}=${v}"
              if !startswith(v, "sm://")
            ]
            secret_env = [
              for item in local.ci_apps_available_secrets[app_source_key] : item.env
            ]
            # go/keep-sorted end
          },
          # Fetches the image digests and pushes a 'latest' tag for each built image.
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "fetchImageDigest"
            name          = "gcr.io/google.com/cloudsdktool/cloud-sdk:$${_GCLOUD_IMAGE_TAG}"
            wait_for      = ["build"]
            allow_failure = false
            dir           = local.app_skaffold_paths[app_source_config.name]
            entrypoint    = "/bin/sh"
            args = [
              "-c",
              file("${path.module}/scripts/fetch_image_digest.sh.template")
            ]
            env = []
            # go/keep-sorted end
          }
        ],
        local.use_binary_authorization ? [
          # Signs the built images using the Kritis signer.
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "vulnsign"
            name          = "$_KRITIS_SIGNER_IMAGE"
            wait_for      = ["fetchImageDigest"]
            allow_failure = true
            dir           = null
            entrypoint    = "/bin/sh"
            args = [
              "-c",
              file("${path.module}/scripts/vulnsign.sh.template")
            ]
            env = []
            # go/keep-sorted end
          }
        ] : [],
        try(google_clouddeploy_delivery_pipeline.continuous_delivery[app_source_config.name].name, "") == "" ? [] : [
          # Creates a Cloud Deploy release from the built artifacts.
          {
            # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args block=yes
            id            = "createRelease"
            name          = "gcr.io/google.com/cloudsdktool/cloud-sdk:$${_GCLOUD_IMAGE_TAG}"
            wait_for      = [local.use_binary_authorization ? "vulnsign" : "fetchImageDigest"]
            allow_failure = false
            dir           = local.app_skaffold_paths[app_source_config.name]
            entrypoint    = "/bin/sh"
            args = [
              "-c",
              file("${path.module}/scripts/create_release.sh.template")
            ]
            env = []
            # go/keep-sorted end
          }
        ]
      )
      timeout          = format("%ds", coalesce(try(app_source_config.config.build.timeout_seconds, null), var.build_timeout_default_seconds))
      has_review_agent = try(app_source_config.config.agents["pre-build"]["review"].enabled, false)
      options = {
        requested_verify_option = "VERIFIED"
        logging                 = "CLOUD_LOGGING_ONLY"
        machine_type            = coalesce(try(app_source_config.config.build.machine_type, null), var.build_machine_type_default, "UNSPECIFIED")
        worker_pool             = var.cloud_build_peered_network != null ? google_cloudbuild_worker_pool.ci_pool[0].id : null
      }
    }
  }

  # Files to include in the Cloud Build context for each application.
  # Automatically resolves recursive transitive skaffold.yaml dependencies and combines with explicit overrides.
  ci_included_files = {
    for app_name, app_config in var.apps : app_name => distinct(compact(concat(
      split(",", data.external.skaffold_deps[app_name].result.included_files),
      try(app_config.build.included_files, [])
    )))
  }

  ci_runner_image = "${local.artifact_registry_repository_uri}/build-runner:latest"

  # Cloud Build substitutions for each app/source combination.
  # Includes details like path to the skaffold.yaml file, image tags, KMS keys, and pipeline names.
  ci_substitutions = {
    for app_source_key, app_source_config in local.ci_apps : app_source_key => {
      # go/keep-sorted start
      _APP_NAME              = app_source_config.name
      _DOCKER_IMAGE_TAG      = var.docker_image_tag
      _GCLOUD_IMAGE_TAG      = var.gcloud_image_tag
      _GIT_CLONE_URL         = local.ci_apps_flags[app_source_key].is_git_repo_webhook ? local.app_source[app_source_config.name].git_repo.url : (local.app_source[app_source_config.name].has_ssm ? local.source_uris[app_source_config.name] : "")
      _GIT_REPO_REF          = local.app_source[app_source_config.name].has_git_repo ? "refs/heads/${local.app_source[app_source_config.name].git_repo.branch}" : ""
      _IS_GIT_REPO_WEBHOOK   = tostring(local.ci_apps_flags[app_source_key].is_git_repo_webhook)
      _KMS_DIGEST_ALG        = var.kms_digest_alg
      _KMS_KEY_NAME          = var.kms_key_name
      _KRITIS_POLICY_BASE64  = base64encode(local.policy_content)
      _KRITIS_SIGNER_IMAGE   = var.kritis_signer_image
      _NAMESPACE             = var.namespace
      _NOTE_NAME             = local.use_binary_authorization ? google_container_analysis_note.vulnz_attestor[0].id : ""
      _PIPELINE_NAME         = try(google_clouddeploy_delivery_pipeline.continuous_delivery[app_source_config.name].name, "")
      _REGION                = var.cloud_build_region
      _SKAFFOLD_DEFAULT_REPO = local.artifact_registry_repository_uri
      _SKAFFOLD_IMAGE_TAG    = var.skaffold_image_tag
      _SKAFFOLD_OUTPUT       = var.skaffold_output
      _SKAFFOLD_PATH         = local.app_skaffold_paths[app_source_config.name]
      _SKAFFOLD_QUIET        = var.skaffold_quiet
      # go/keep-sorted end
    }
  }

  # The content of the Kritis policy file, or the default policy if not specified. Empty if Binary Authorization is not used.
  kritis_policy = var.kritis_policy_file == null ? var.kritis_policy_default : file(var.kritis_policy_file)

  policy_content = local.use_binary_authorization ? local.kritis_policy : ""

  # The source repository solution: GitHub or Secure Source Manager.
  source_solution = local.source.github ? "github" : (local.source.ssm ? "ssm" : null)

  # The URI for the source repository, either from GitHub or Secure Source Manager.
  source_uris = {
    for k, v in local.app_source : k =>
    v.has_github ? "https://github.com/${v.github.owner}/${v.github.repo}.git" : (
      v.has_ssm ? google_secure_source_manager_repository.cicd_foundation[0].uris[0].git_https : (
        v.has_git_repo ? v.git_repo.url : ""
      )
    )
  }
  # go/keep-sorted end
}

# Automatically resolve transitive skaffold.yaml dependencies recursively
data "external" "skaffold_deps" {
  for_each = var.apps
  program  = ["python3", "${path.module}/scripts/resolve_skaffold_deps.py"]
  query = {
    skaffold_path = local.app_skaffold_paths[each.key]
    repo_root     = abspath("${path.module}/../../..")
  }
}

# cf. https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts
module "service_account_cloud_build" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  project_id   = local.build_project_id
  name         = "${local.prefix}${var.cloud_build_service_account_name}"
  display_name = "Cloud Build Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (local.build_project_id) : concat([
      # go/keep-sorted start
      "roles/cloudbuild.builds.builder",
      "roles/clouddeploy.releaser",
      "roles/containeranalysis.notes.attacher",
      "roles/containeranalysis.notes.occurrences.viewer",
      "roles/containeranalysis.occurrences.editor",
      "roles/logging.logWriter",
      # go/keep-sorted end
    ], local.needs_agent_platform_access ? ["roles/aiplatform.user"] : [])
  }
}

resource "google_cloudbuild_worker_pool" "ci_pool" {
  count = var.cloud_build_peered_network != null ? 1 : 0

  project  = data.google_project.project.project_id
  name     = "${local.prefix}${var.cloud_build_pool_name}-ci"
  location = var.cloud_build_region
  network_config {
    peered_network = var.cloud_build_peered_network
  }
  worker_config {
    disk_size_gb   = var.cloud_build_pool_disk_size_gb
    machine_type   = var.cloud_build_pool_machine_type
    no_external_ip = true
  }
}

resource "google_cloudbuild_worker_pool" "pool" {
  for_each = { for k, v in var.stages : k => v if v.peered_network != null }

  project  = var.stages[each.key].project_id
  name     = "${local.prefix}${var.cloud_build_pool_name}-${each.key}"
  location = var.cloud_build_region
  worker_config {
    disk_size_gb   = var.cloud_build_pool_disk_size_gb
    machine_type   = var.cloud_build_pool_machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = var.stages[each.key].peered_network
  }
}

resource "google_cloudbuild_trigger" "ci_pipeline" {
  for_each = local.ci_build_specs

  project         = local.build_project_id
  name            = "${local.prefix}${each.value.name}${each.value.postfix}"
  location        = var.cloud_build_region
  service_account = module.service_account_cloud_build.id
  description     = "Terraform-managed."

  # go/keep-sorted start block=yes newline_separated=yes
  dynamic "github" {
    for_each = local.ci_apps_flags[each.key].is_github_trigger ? [1] : []

    content {
      owner = local.app_source[each.value.name].github.owner
      name  = local.app_source[each.value.name].github.repo
      push {
        branch = local.app_source[each.value.name].github.branch_pattern
      }
    }
  }

  dynamic "source_to_build" {
    for_each = local.ci_apps_flags[each.key].needs_source_to_build ? [1] : []

    content {
      uri       = local.source_uris[each.value.name]
      ref       = "refs/heads/${var.git_branch_trigger}"
      repo_type = "GITHUB"
    }
  }

  dynamic "webhook_config" {
    for_each = local.ci_apps_flags[each.key].is_webhook_trigger ? [1] : []

    content {
      secret = google_secret_manager_secret_version.webhook_trigger[0].id
    }
  }
  # go/keep-sorted end

  build {
    dynamic "step" {
      for_each = each.value.steps

      content {
        # go/keep-sorted start prefix_order=id,name,wait_for,allow_failure,dir,entrypoint,args,env block=yes
        id            = step.value.id
        name          = step.value.name
        wait_for      = step.value.wait_for
        allow_failure = step.value.allow_failure
        dir           = step.value.dir
        entrypoint    = step.value.entrypoint
        args          = step.value.args
        env           = step.value.env
        secret_env    = try(step.value.secret_env, [])
        # go/keep-sorted end
      }
    }

    dynamic "available_secrets" {
      for_each = length(local.ci_apps_available_secrets[each.key]) > 0 ? [1] : []
      content {
        dynamic "secret_manager" {
          for_each = local.ci_apps_available_secrets[each.key]
          content {
            version_name = secret_manager.value.version_name
            env          = secret_manager.value.env
          }
        }
      }
    }

    timeout = each.value.timeout

    dynamic "artifacts" {
      for_each = each.value.has_review_agent ? [1] : []

      content {
        objects {
          location = "gs://${google_storage_bucket.cloudbuild_source.name}/reports/${each.value.name}/$${BUILD_ID}/"
          paths    = ["report.md"]
        }
      }
    }

    options {
      requested_verify_option = each.value.options.requested_verify_option
      logging                 = each.value.options.logging
      machine_type            = each.value.options.machine_type
      worker_pool             = each.value.options.worker_pool
    }
  }
  included_files = local.ci_included_files[each.value.name]
  substitutions  = local.ci_substitutions[each.key]

  lifecycle {
    ignore_changes = [
      included_files,
      source_to_build,
    ]
  }
}

# Dedicated GCS bucket to store Cloud Build source archives
resource "google_storage_bucket" "cloudbuild_source" {
  project                     = local.build_project_id
  name                        = "${local.prefix}cloudbuild-source-${local.build_project_id}"
  location                    = var.cloud_build_region
  uniform_bucket_level_access = true

  # Auto-delete source archives after 7 days to prevent GCS storage bloat
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.build_source_retention_days
    }
  }
}

# Grant storage object admin permission to the custom Cloud Build service account
# on the staging bucket to allow it to read sources and write execution logs (Least Privilege)
resource "google_storage_bucket_iam_member" "cloudbuild_source_admin" {
  bucket = google_storage_bucket.cloudbuild_source.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.service_account_cloud_build.email}"
}

# Bootstrap the build-runner image
resource "null_resource" "build_bootstrap_runner" {
  triggers = {
    # Re-run the build if any file inside the build-runner directory changes
    runner_source_sha = sha256(join("", [
      for f in fileset("${path.module}/../../../apps/build-runner", "**") : filesha256("${path.module}/../../../apps/build-runner/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit \
        --tag ${local.artifact_registry_repository_uri}/build-runner:latest \
        --project ${local.build_project_id} \
        --region ${var.cloud_build_region} \
        --service-account "projects/${local.build_project_id}/serviceAccounts/${module.service_account_cloud_build.email}" \
        --gcs-source-staging-dir "gs://${google_storage_bucket.cloudbuild_source.name}/source" \
        --gcs-log-dir "gs://${google_storage_bucket.cloudbuild_source.name}/logs" \
        --timeout 1200s \
        ${path.module}/../../../apps/build-runner
    EOT
  }

  depends_on = [
    module.docker_artifact_registry,
    google_storage_bucket_iam_member.cloudbuild_source_admin,
  ]
}

