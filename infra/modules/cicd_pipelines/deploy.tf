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

module "service_account_cloud_deploy" {
  for_each = length(local.cloud_deploy_apps) > 0 ? var.stages : {}

  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v45.0.0"

  project_id   = coalesce(each.value.project_id, var.project_id)
  name         = "${local.prefix}${var.service_account_cloud_deploy_name}-${each.key}"
  display_name = "Cloud Deploy Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (coalesce(each.value.project_id, local.build_project_id)) : concat(
      length([for _, c in var.apps : c if try(c.runtime, "") == "gke"]) > 0 ? [
        "roles/container.developer",
      ] : [],
      length([for _, c in var.apps : c if try(c.runtime, "") == "cloudrun"]) > 0 ? [
        "roles/run.developer",
      ] : [],
      length([for _, c in var.apps : c if try(c.runtime, "") == "agentruntime"]) > 0 ? [
        "roles/aiplatform.user",
      ] : [],
    ),
    # cf. https://cloud.google.com/deploy/docs/cloud-deploy-service-account#execution_service_account
    (data.google_project.project.project_id) : [
      "roles/clouddeploy.jobRunner",
      "roles/clouddeploy.releaser",
      "roles/logging.logWriter",
      "roles/storage.objectUser",
      "roles/artifactregistry.writer",
      "roles/cloudbuild.builds.editor",
    ]
  }
  # cf. https://cloud.google.com/deploy/docs/cloud-deploy-service-account#using_service_accounts_from_a_different_project
  iam = {
    "roles/iam.serviceAccountUser" = [
      # ad 4)
      module.service_account_cloud_build.iam_email,
      # ad 2)
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-clouddeploy.iam.gserviceaccount.com",
    ],
    "roles/iam.serviceAccountTokenCreator" = [
      # ad 3)
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    ],
  }
}

resource "google_clouddeploy_target" "cluster" {
  for_each = length(local.cloud_deploy_apps) > 0 ? { for key, value in var.stages : key => value if value.gke_cluster != null } : {}

  project     = local.build_project_id
  name        = "${local.prefix}cluster-${each.key}"
  location    = var.deploy_region
  description = "Terraform-managed."
  gke {
    cluster     = each.value.gke_cluster
    internal_ip = false
  }
  require_approval = each.value.require_approval
  execution_configs {
    worker_pool = try(google_cloudbuild_worker_pool.pool[each.key].id, null)
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.service_account_cloud_deploy[each.key].email
  }
  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_clouddeploy_target" "run" {
  for_each = length(local.cloud_deploy_apps) > 0 ? { for key, value in var.stages : key => value if value.cloud_run_region != null } : {}

  project     = local.build_project_id
  name        = "${local.prefix}run-${each.key}"
  location    = var.deploy_region
  description = "Terraform-managed."
  run {
    location = each.value.cloud_run_region
  }
  require_approval = each.value.require_approval
  execution_configs {
    worker_pool = try(google_cloudbuild_worker_pool.pool[each.key].id, null)
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.service_account_cloud_deploy[each.key].email
  }
  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_clouddeploy_custom_target_type" "agentruntime" {
  count    = length([for _, c in var.apps : c if try(c.runtime, "") == "agentruntime"]) > 0 ? 1 : 0
  project  = local.build_project_id
  location = var.deploy_region
  name     = "${local.prefix}agentruntime"

  custom_actions {
    render_action = "render-agentruntime"
    deploy_action = "deploy-agentruntime"
  }
}

resource "google_clouddeploy_target" "agentruntime" {
  for_each = length(local.cloud_deploy_apps) > 0 ? {
    for key, value in var.stages : key => value
    if length([for _, c in var.apps : c if try(c.runtime, "") == "agentruntime"]) > 0
  } : {}

  project          = local.build_project_id
  name             = "${local.prefix}agentruntime-${each.key}"
  location         = var.deploy_region
  description      = "Terraform-managed."
  require_approval = each.value.require_approval
  execution_configs {
    worker_pool = try(google_cloudbuild_worker_pool.pool[each.key].id, null)
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.service_account_cloud_deploy[each.key].email
  }

  custom_target {
    custom_target_type = google_clouddeploy_custom_target_type.agentruntime[0].id
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_project_service_identity" "iap" {
  count   = length([for _, c in var.apps : c if try(c.runtime, "") == "agentruntime"]) > 0 ? 1 : 0
  project = local.build_project_id
  service = "iap.googleapis.com"
}

resource "google_clouddeploy_delivery_pipeline" "continuous_delivery" {
  for_each = local.cloud_deploy_apps

  project     = local.build_project_id
  location    = var.deploy_region
  name        = "${local.prefix}${each.key}"
  description = "Terraform-managed."
  serial_pipeline {
    dynamic "stages" {
      for_each = keys(var.stages)

      content {
        profiles  = [stages.value]
        target_id = each.value.runtime == "gke" ? google_clouddeploy_target.cluster[stages.value].name : (each.value.runtime == "agentruntime" ? google_clouddeploy_target.agentruntime[stages.value].name : google_clouddeploy_target.run[stages.value].name)
        dynamic "deploy_parameters" {
          for_each = each.value.stages[stages.value]

          content {
            values = {
              "ENV"                 = stages.value
              deploy_parameters.key = deploy_parameters.value
            }
          }
        }
        dynamic "strategy" {
          for_each = var.stages[stages.value].canary_percentages == null ? [] : [0]

          content {
            canary {
              runtime_config {
                kubernetes {
                  gateway_service_mesh {
                    deployment             = each.key
                    http_route             = each.key
                    route_update_wait_time = "${var.canary_route_update_wait_time_seconds}s"
                    service                = each.key
                  }
                }
              }
              canary_deployment {
                percentages = var.stages[stages.value].canary_percentages
                verify      = var.stages[stages.value].canary_verify
              }
            }
          }
        }
      }
    }
  }
  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_clouddeploy_automation" "promote-release" {
  for_each = local.cloud_deploy_apps

  name              = "${local.prefix}${each.key}"
  project           = google_clouddeploy_delivery_pipeline.continuous_delivery[each.key].project
  location          = google_clouddeploy_delivery_pipeline.continuous_delivery[each.key].location
  delivery_pipeline = google_clouddeploy_delivery_pipeline.continuous_delivery[each.key].name
  description       = "Terraform-managed."
  service_account   = module.service_account_cloud_build.email
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
  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}
