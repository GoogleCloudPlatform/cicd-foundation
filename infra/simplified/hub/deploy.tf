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

module "sa-cd-prod" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = module.project.project_id
  name         = "${var.sa_cd_name}-prod"
  display_name = "Cloud Deploy Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project.project_id) : [
      "roles/clouddeploy.jobRunner",
      "roles/clouddeploy.releaser",
      "roles/logging.logWriter",
      "roles/container.developer",
      "roles/run.developer",
    ]
  }
  iam = {
    "roles/iam.serviceAccountUser" = concat([
      module.sa-cb.iam_email,
      module.project.service_agents["clouddeploy"].iam_email,
    ], var.developers),
  }
}

module "sa-cd-test" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = module.project.project_id
  name         = "${var.sa_cd_name}-test"
  display_name = "Cloud Deploy Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project.project_id) : [
      "roles/clouddeploy.jobRunner",
      "roles/clouddeploy.releaser",
      "roles/logging.logWriter",
      "roles/container.developer",
      "roles/run.developer",
    ]
  }
  iam = {
    "roles/iam.serviceAccountUser" = concat([
      module.sa-cb.iam_email,
      module.project.service_agents["clouddeploy"].iam_email,
    ], var.developers),
  }
}

module "sa-cd-dev" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = module.project.project_id
  name         = "${var.sa_cd_name}-dev"
  display_name = "Cloud Deploy Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project.project_id) : [
      "roles/clouddeploy.jobRunner",
      "roles/clouddeploy.releaser",
      "roles/logging.logWriter",
      "roles/container.developer",
      "roles/run.developer",
    ]
  }
  iam = {
    "roles/iam.serviceAccountUser" = [
      module.sa-cb.iam_email,
      module.project.service_agents["clouddeploy"].iam_email,
    ],
  }
}

resource "google_clouddeploy_target" "cluster-prod" {
  project     = module.project.project_id
  location    = var.region
  name        = "cluster-prod"
  description = "Terraform-managed."
  gke {
    cluster     = "projects/${module.project.id}/locations/${module.cluster-prod.location}/clusters/${module.cluster-prod.name}"
    internal_ip = false
  }
  require_approval = true
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.prod.project}/locations/${google_cloudbuild_worker_pool.prod.location}/workerPools/${google_cloudbuild_worker_pool.prod.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-prod.email
  }
}

resource "google_clouddeploy_target" "cluster-test" {
  project     = module.project.project_id
  location    = var.region
  name        = "cluster-test"
  description = "Terraform-managed."
  gke {
    cluster     = "projects/${module.project.id}/locations/${module.cluster-test.location}/clusters/${module.cluster-test.name}"
    internal_ip = false
  }
  require_approval = false
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.test.project}/locations/${google_cloudbuild_worker_pool.test.location}/workerPools/${google_cloudbuild_worker_pool.test.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-test.email
  }
}

resource "google_clouddeploy_target" "cluster-dev" {
  project     = module.project.project_id
  location    = var.region
  name        = "cluster-dev"
  description = "Terraform-managed."
  gke {
    cluster     = "projects/${module.project.id}/locations/${module.cluster-dev.location}/clusters/${module.cluster-dev.name}"
    internal_ip = false
  }
  require_approval = false
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.dev.project}/locations/${google_cloudbuild_worker_pool.dev.location}/workerPools/${google_cloudbuild_worker_pool.dev.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-dev.email
  }
}

resource "google_clouddeploy_target" "run-prod" {
  project     = module.project.project_id
  location    = var.region
  name        = "run-prod"
  description = "Terraform-managed."
  run {
    location = "projects/${module.project.id}/locations/${var.region}"
  }
  require_approval = true
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.prod.project}/locations/${google_cloudbuild_worker_pool.prod.location}/workerPools/${google_cloudbuild_worker_pool.prod.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-prod.email
  }
}

resource "google_clouddeploy_target" "run-test" {
  project     = module.project.project_id
  location    = var.region
  name        = "run-test"
  description = "Terraform-managed."
  run {
    location = "projects/${module.project.id}/locations/${var.region}"
  }
  require_approval = false
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.test.project}/locations/${google_cloudbuild_worker_pool.test.location}/workerPools/${google_cloudbuild_worker_pool.test.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-test.email
  }
}

resource "google_clouddeploy_target" "run-dev" {
  project     = module.project.project_id
  location    = var.region
  name        = "run-dev"
  description = "Terraform-managed."
  run {
    location = "projects/${module.project.id}/locations/${var.region}"
  }
  require_approval = false
  execution_configs {
    #worker_pool = "projects/${google_cloudbuild_worker_pool.dev.project}/locations/${google_cloudbuild_worker_pool.dev.location}/workerPools/${google_cloudbuild_worker_pool.dev.name}"
    usages = [
      "RENDER",
      "DEPLOY",
    ]
    service_account = module.sa-cd-dev.email
  }
}
