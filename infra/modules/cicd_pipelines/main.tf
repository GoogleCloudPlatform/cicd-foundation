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
  activate_apis = concat([
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "ondemandscanning.googleapis.com",
    "binaryauthorization.googleapis.com",
    ],
    length(local.cloud_deploy_apps) > 0 ? ["clouddeploy.googleapis.com"] : [],
    length(local.scheduled_apps) > 0 ? ["cloudscheduler.googleapis.com"] : [],
    local.source.ssm ? ["apikeys.googleapis.com", "securesourcemanager.googleapis.com"] : []
  )

  app_source = {
    for k, v in var.apps : k => {
      # go/keep-sorted start block=yes
      git_repo = v.git_repo
      github = v.github != null ? v.github : (v.ssm == null && v.git_repo == null && local.source.github ? {
        owner          = var.github_owner
        repo           = var.github_repo
        branch_pattern = var.git_branches_regexp_trigger
      } : null)
      has_git_repo = v.git_repo != null
      has_github   = v.github != null || (v.ssm == null && v.git_repo == null && local.source.github)
      has_ssm      = v.ssm != null || (v.github == null && v.git_repo == null && local.source.ssm)
      ssm = v.ssm != null ? v.ssm : (v.github == null && v.git_repo == null && local.source.ssm ? {
        instance_id = local.ssm_instance_id
        repo_name   = var.secure_source_manager_repo_name
        branch      = var.git_branch_trigger
      } : null)
      # go/keep-sorted end
    }
  }

  artifact_registry_project_id = data.google_project.project.project_id

  artifact_registry_repository_uri = format(
    "%s-docker.pkg.dev/%s/%s",
    data.google_artifact_registry_repository.container_repository.location,
    local.artifact_registry_project_id,
    data.google_artifact_registry_repository.container_repository.repository_id
  )

  build_project_id = data.google_project.project.project_id

  # A filtered product of applications and trigger types.
  # Each entry contains the name (from var.apps), the corresponding config (from var.apps), and the trigger type (from local.trigger_sources).
  # Webhook triggers are created if using SSM or `git_repo`.
  # Manual and GitHub triggers are only created if using GitHub.
  ci_apps = {
    for app_source_pair in setproduct(keys(var.apps), ["github", "manual", "webhook"]) : contains(["github", "manual"], app_source_pair[1]) ? "${app_source_pair[0]}-${app_source_pair[1]}" : "${app_source_pair[0]}" => {
      name         = app_source_pair[0]
      config       = var.apps[app_source_pair[0]]
      trigger_type = app_source_pair[1]
    }
    if(
      (app_source_pair[1] == "webhook" && (local.app_source[app_source_pair[0]].has_ssm || local.app_source[app_source_pair[0]].has_git_repo)) ||
      (app_source_pair[1] == "github" && local.app_source[app_source_pair[0]].has_github) ||
      (app_source_pair[1] == "manual" && local.app_source[app_source_pair[0]].has_github)
    )
  }

  ci_apps_available_secrets = {
    for k, v in local.ci_apps_secrets_filtered : k => [
      for item in v : {
        env = item.env_name
        version_name = (
          startswith(item.secret_ref, "projects/") ?
          item.secret_ref :
          length(split("/", item.secret_ref)) == 2 ?
          "projects/${local.build_project_id}/secrets/${split("/", item.secret_ref)[0]}/versions/${split("/", item.secret_ref)[1]}" :
          "projects/${local.build_project_id}/secrets/${item.secret_ref}/versions/latest"
        )
      }
    ]
  }

  # Boolean flags for each application source combination.
  # This helps in conditionally configuring build steps and trigger settings.
  ci_apps_flags = {
    for k, v in local.ci_apps : k => {
      is_github_trigger     = v.trigger_type == "github",
      is_webhook_trigger    = v.trigger_type == "webhook",
      is_git_repo_webhook   = v.trigger_type == "webhook" && local.app_source[v.name].has_git_repo,
      needs_source_to_build = v.trigger_type == "manual" && local.app_source[v.name].has_github,
      needs_clone_step      = (v.trigger_type == "webhook" && local.app_source[v.name].has_git_repo) || local.app_source[v.name].has_ssm
    }
  }

  ci_apps_secrets = {
    for app_source_key, app_source_config in local.ci_apps : app_source_key => [
      for env_key, env_val in try(app_source_config.config.build.env, {}) : {
        env_name   = env_key
        is_secret  = startswith(env_val, "sm://")
        secret_ref = startswith(env_val, "sm://") ? replace(env_val, "sm://", "") : ""
      }
    ]
  }

  ci_apps_secrets_filtered = {
    for k, v in local.ci_apps_secrets : k => [
      for item in v : item if item.is_secret
    ]
  }

  cloud_deploy_apps = {
    for key, value in var.apps : key => value
    if value.runtime != null && contains(local.cloud_deploy_supported_runtimes, value.runtime)
  }

  cloud_deploy_supported_runtimes = ["cloudrun", "gke"]

  # merge the default labels with the user-provided labels and convert to lowercase
  common_labels = {
    for k, v in merge(var.labels, local.default_labels) : lower(k) => lower(v)
  }

  create_webhook_trigger = local.source.ssm || length([for k, v in local.ci_apps_flags : k if v.is_webhook_trigger]) > 0

  default_labels = {
    "tf_module_github_org"  = "GoogleCloudPlatform"
    "tf_module_github_repo" = "cicd-foundation"
    "tf_module_name"        = "cicd_pipelines"
    "tf_module_version"     = "v8-0-0"
  }

  kms_project_id = data.google_project.project.project_id

  needs_agent_platform_access = anytrue([
    for app_name, app_config in var.apps : try(app_config.agents["pre-build"]["review"].enabled, false)
  ])

  prefix = var.namespace == "" ? "" : "${var.namespace}-"

  scheduled_apps = var.apps

  source = {
    github = var.github_owner != null && var.github_repo != null
    ssm    = var.secure_source_manager_always_create || (var.github_owner == null && var.github_repo == null && anytrue([for k, v in var.apps : v.github == null && v.git_repo == null]))
  }

  workstation_apps = { for k, v in var.apps : k => v if v.runtime == "workstations" }
  # go/keep-sorted end
}

data "google_project" "project" {
  project_id = var.project_id

  depends_on = [
    module.project_services
  ]
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.2.0"

  project_id                  = var.project_id
  enable_apis                 = var.enable_apis
  disable_services_on_destroy = false
  activate_apis               = local.activate_apis
}

resource "google_apikeys_key" "cloud_build" {
  count = local.source.ssm ? 1 : 0

  project      = data.google_project.project.project_id
  name         = var.cloud_build_api_key_name
  display_name = var.cloud_build_api_key_display_name
  restrictions {
    api_targets {
      service = "cloudbuild.googleapis.com"
    }
  }

  depends_on = [
    module.project_services
  ]
}
