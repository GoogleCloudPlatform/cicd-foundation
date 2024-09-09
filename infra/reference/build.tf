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

# cf. https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts
module "sa-cb" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account?ref=v34.0.0"
  project_id   = module.project_hub_supplychain.id
  name         = var.sa_cb_name
  display_name = "Cloud Build Service Account"
  description  = "Terraform-managed."
  iam_project_roles = {
    (module.project_hub_supplychain.id) : [
      "roles/cloudbuild.builds.builder",
      "roles/clouddeploy.releaser",
      "roles/containeranalysis.notes.occurrences.viewer",
      "roles/containeranalysis.occurrences.viewer",
    ],
  }
}

resource "google_cloudbuild_worker_pool" "prod" {
  name     = var.cb_pool_name
  project  = module.project_prod_supplychain.project_id
  location = var.region
  worker_config {
    disk_size_gb   = var.cb_pool_disk_size_gb
    machine_type   = var.cb_pool_machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = module.vpc-prod-build.id
  }
}

resource "google_cloudbuild_worker_pool" "test" {
  name     = var.cb_pool_name
  project  = module.project_test_supplychain.project_id
  location = var.region
  worker_config {
    disk_size_gb   = var.cb_pool_disk_size_gb
    machine_type   = var.cb_pool_machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = module.vpc-dev-build.id
  }
}

resource "google_cloudbuild_worker_pool" "dev" {
  name     = var.cb_pool_name
  project  = module.project_dev_supplychain.project_id
  location = var.region
  worker_config {
    disk_size_gb   = var.cb_pool_disk_size_gb
    machine_type   = var.cb_pool_machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = module.vpc-dev-build.id
  }
}

module "docker_artifact_registry" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/artifact-registry?ref=v34.0.0"
  project_id = module.project_hub_supplychain.project_id
  name       = var.registry_id
  location   = var.region
  format = {
    docker = {
      standard = {}
    }
  }
  iam = {
    "roles/artifactregistry.reader" = [
      module.sa-cb.iam_email,
      "serviceAccount:service-${module.project_hub_supplychain.number}@gcp-sa-workstationsvm.iam.gserviceaccount.com",
      module.sa-cluster-prod.iam_email,
      module.sa-cluster-test.iam_email,
      module.sa-cluster-dev.iam_email,
    ],
    "roles/artifactregistry.writer" = [
      module.sa-cb.iam_email,
    ],
  }
}
