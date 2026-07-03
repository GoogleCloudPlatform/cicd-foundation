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
  # go/keep-sorted start
  cloudbuild_service_agent        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  cloudbuild_webhook_uri_template = "https://cloudbuild.googleapis.com/v1/projects/%s/locations/%s/triggers/%s:webhook"
  create_ssm_ca_pool              = local.source.ssm && !local.ssm_instance_is_provided && var.secure_source_manager_create_ca_pool && var.secure_source_manager_ca_pool == null
  ssm_instance_accessor_members = toset(concat(
    [module.service_account_cloud_build.iam_email],
    length(google_service_account.git_clone_and_push) > 0 ? [google_service_account.git_clone_and_push[0].member] : [],
  ))
  ssm_instance_ca_pool = var.secure_source_manager_ca_pool != null ? var.secure_source_manager_ca_pool : (local.create_ssm_ca_pool ? google_privateca_ca_pool.ssm_ca_pool[0].id : null)
  ssm_instance_id = local.source.ssm ? (
    local.ssm_instance_is_provided ?
    var.secure_source_manager_instance_id :
    google_secure_source_manager_instance.cicd_foundation[0].id
  ) : null
  ssm_instance_is_provided = var.secure_source_manager_instance_id != null
  ssm_instance_name        = local.ssm_instance_is_provided ? split("/", var.secure_source_manager_instance_id)[5] : var.secure_source_manager_instance_name
  ssm_location             = local.ssm_instance_is_provided ? split("/", var.secure_source_manager_instance_id)[3] : var.secure_source_manager_region
  ssm_project              = local.ssm_instance_is_provided ? split("/", var.secure_source_manager_instance_id)[1] : data.google_project.project.project_id
  # go/keep-sorted end
}

# Secure Source Manager (SSM) CA Pool

resource "google_privateca_ca_pool" "ssm_ca_pool" {
  count = local.create_ssm_ca_pool ? 1 : 0

  name     = "${local.prefix}ssm-ca-pool"
  location = var.secure_source_manager_region
  tier     = "ENTERPRISE"
  project  = data.google_project.project.project_id
  labels   = local.common_labels
  publishing_options {
    publish_ca_cert = true
    publish_crl     = true
  }
}

resource "google_privateca_certificate_authority" "ssm_root_ca" {
  count = local.create_ssm_ca_pool ? 1 : 0

  pool                     = google_privateca_ca_pool.ssm_ca_pool[0].name
  certificate_authority_id = "${local.prefix}ssm-root-ca"
  location                 = var.secure_source_manager_region
  project                  = data.google_project.project.project_id
  deletion_protection      = false
  config {
    subject_config {
      subject {
        organization = var.secure_source_manager_ca_organization
        common_name  = var.secure_source_manager_ca_common_name
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }
  lifetime = var.secure_source_manager_ca_lifetime_seconds
  key_spec {
    algorithm = var.secure_source_manager_ca_key_algorithm
  }
}

# Secure Source Manager (SSM) Instance

resource "google_secure_source_manager_instance" "cicd_foundation" {
  count = local.source.ssm && !local.ssm_instance_is_provided ? 1 : 0

  project         = data.google_project.project.project_id
  location        = var.secure_source_manager_region
  instance_id     = var.secure_source_manager_instance_name
  labels          = local.common_labels
  deletion_policy = var.secure_source_manager_deletion_policy
  dynamic "private_config" {
    for_each = local.ssm_instance_ca_pool == null ? [] : [1]
    content {
      is_private = true
      ca_pool    = local.ssm_instance_ca_pool
    }
  }

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_secure_source_manager_instance_iam_member" "instance_accessor" {
  for_each = local.source.ssm ? local.ssm_instance_accessor_members : toset([])

  project     = local.ssm_project
  location    = local.ssm_location
  instance_id = local.ssm_instance_name
  role        = "roles/securesourcemanager.instanceAccessor"
  member      = each.value

  depends_on = [google_secure_source_manager_instance.cicd_foundation]
}

# Secure Source Manager (SSM) Repository

resource "google_secure_source_manager_repository" "cicd_foundation" {
  count = local.source.ssm ? 1 : 0

  project         = local.ssm_project
  location        = local.ssm_location
  instance        = local.ssm_instance_id
  repository_id   = "${local.prefix}${var.secure_source_manager_repo_name}"
  deletion_policy = var.secure_source_manager_deletion_policy

  depends_on = [google_secure_source_manager_instance.cicd_foundation]
}

resource "google_secure_source_manager_repository_iam_binding" "repo_reader" {
  count = local.source.ssm ? 1 : 0

  project       = google_secure_source_manager_repository.cicd_foundation[0].project
  location      = google_secure_source_manager_repository.cicd_foundation[0].location
  repository_id = google_secure_source_manager_repository.cicd_foundation[0].repository_id
  role          = "roles/securesourcemanager.repoReader"
  members       = [module.service_account_cloud_build.iam_email]
}

# Webhook

resource "google_secret_manager_secret" "webhook_trigger" {
  count = local.create_webhook_trigger ? 1 : 0

  project   = data.google_project.project.project_id
  secret_id = "${local.prefix}webhook-trigger"
  replication {
    user_managed {
      replicas {
        location = var.secret_manager_region
      }
    }
  }
}

resource "random_id" "webhook_secret_key" {
  count = local.create_webhook_trigger ? 1 : 0

  byte_length = 64
}

resource "google_secret_manager_secret_version" "webhook_trigger" {
  count = local.create_webhook_trigger ? 1 : 0

  secret      = google_secret_manager_secret.webhook_trigger[0].id
  secret_data = random_id.webhook_secret_key[0].hex
}

data "google_iam_policy" "secret_accessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  count = local.create_webhook_trigger ? 1 : 0

  project     = google_secret_manager_secret.webhook_trigger[0].project
  secret_id   = google_secret_manager_secret.webhook_trigger[0].secret_id
  policy_data = data.google_iam_policy.secret_accessor.policy_data
}

resource "google_secure_source_manager_hook" "cicd_foundation" {
  for_each = { for k, v in local.ci_apps_flags : k => google_cloudbuild_trigger.ci_pipeline[k] if local.source.ssm && v.is_webhook_trigger }

  project       = google_secure_source_manager_repository.cicd_foundation[0].project
  hook_id       = each.value.name
  repository_id = google_secure_source_manager_repository.cicd_foundation[0].repository_id
  location      = google_secure_source_manager_repository.cicd_foundation[0].location
  target_uri = format(
    local.cloudbuild_webhook_uri_template,
    each.value.project,
    each.value.location,
    each.value.name
  )
  sensitive_query_string = join("&", [
    "key=${google_apikeys_key.cloud_build[0].key_string}",
    "secret=${google_secret_manager_secret_version.webhook_trigger[0].secret_data}",
    "trigger=${each.value.name}",
    "projectId=${google_secure_source_manager_repository.cicd_foundation[0].project}"
  ])
  push_option {
    branch_filter = var.git_branch_trigger
  }
  events = ["PUSH"]
}

# Clone a Git repo and push to Secure Source Manager (SSM) Repository

resource "google_service_account" "git_clone_and_push" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  project      = data.google_project.project.project_id
  account_id   = "tf-${local.prefix}git-clone"
  display_name = "SA for git-clone-and-push trigger"
  description  = "Terraform-managed."
}

resource "google_project_iam_member" "git_clone_and_push_log_writer" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = google_service_account.git_clone_and_push[0].member
}

resource "google_service_account_iam_member" "git_clone_and_push_cb_user" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  service_account_id = google_service_account.git_clone_and_push[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = local.cloudbuild_service_agent
}

resource "google_secure_source_manager_repository_iam_binding" "repo_writer_git_clone" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  project       = google_secure_source_manager_repository.cicd_foundation[0].project
  location      = google_secure_source_manager_repository.cicd_foundation[0].location
  repository_id = google_secure_source_manager_repository.cicd_foundation[0].repository_id
  role          = "roles/securesourcemanager.repoWriter"
  members       = [google_service_account.git_clone_and_push[0].member]
}

resource "google_cloudbuild_trigger" "git_clone_and_push" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  project         = data.google_project.project.project_id
  name            = "tf-git-clone-and-push"
  location        = var.cloud_build_region
  service_account = google_service_account.git_clone_and_push[0].id
  description     = "Terraform managed."
  webhook_config {
    secret = google_secret_manager_secret_version.webhook_trigger[0].id
  }
  build {
    step {
      name       = "gcr.io/cloud-builders/git"
      id         = "git-clone-and-push"
      entrypoint = "sh"
      args = [
        "-c",
        <<EOT
          git config --global user.name "$${_USER_NAME}" && \
          git config --global user.email "$${_USER_EMAIL}" && \
          git config --global credential.'https://*.*.sourcemanager.dev'.helper gcloud.sh && \
          git clone $${_SOURCE_REPO_URL} . && \
          git remote add private $${_TARGET_REPO_URL} && \
          git push private $${_BRANCH_NAME}
        EOT
      ]
    }
    substitutions = {
      _BRANCH_NAME     = var.git_branch_trigger
      _SOURCE_REPO_URL = var.secure_source_manager_repo_git_url_to_clone
      _TARGET_REPO_URL = google_secure_source_manager_repository.cicd_foundation[0].uris[0].git_https
      _USER_EMAIL      = google_service_account.git_clone_and_push[0].email
      _USER_NAME       = "github.com/${local.default_labels["tf_module_github_org"]}/${local.default_labels["tf_module_github_repo"]}"
    }
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
  }
}

resource "null_resource" "run_git_clone_and_push" {
  count = local.source.ssm && var.secure_source_manager_repo_git_url_to_clone != null ? 1 : 0

  triggers = {
    ssm_repository_id = google_secure_source_manager_repository.cicd_foundation[0].id
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds triggers run \
        ${google_cloudbuild_trigger.git_clone_and_push[0].name} \
        --region=${var.cloud_build_region} \
        --project=${data.google_project.project.project_id}
    EOT
  }
  depends_on = [
    google_cloudbuild_trigger.git_clone_and_push,
    google_secure_source_manager_instance_iam_member.instance_accessor,
    google_secure_source_manager_repository_iam_binding.repo_writer_git_clone,
  ]
}

resource "null_resource" "run_git_repo_trigger" {
  for_each = {
    for k, v in local.ci_apps_flags : k => v
    if v.is_git_repo_webhook
  }

  triggers = {
    trigger_id    = google_cloudbuild_trigger.ci_pipeline[each.key].id
    build_json    = jsonencode(local.ci_build_specs[each.key].steps)
    substitutions = jsonencode(local.ci_substitutions[each.key])
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds triggers run \
        ${google_cloudbuild_trigger.ci_pipeline[each.key].name} \
        --region=${var.cloud_build_region} \
        --project=${local.build_project_id}
    EOT
  }

  depends_on = [
    google_cloudbuild_trigger.ci_pipeline,
  ]
}
