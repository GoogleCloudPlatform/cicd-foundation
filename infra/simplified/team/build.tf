# Copyright 2023 Google LLC
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

module "docker_artifact_registry" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/artifact-registry?ref=v24.0.0"
  project_id = var.project_hub_id
  id         = "${var.team-prefix}-${var.registry_id}"
  location   = var.region
  format     = "DOCKER"
  iam = {
    "roles/artifactregistry.reader" = [
      "serviceAccount:${module.sa-cluster-dev.email}",
      "serviceAccount:${module.sa-cluster-test.email}",
      "serviceAccount:${module.sa-cluster-prod.email}",
      "serviceAccount:${var.sa-cb-email}"
    ],
    "roles/artifactregistry.writer" = [
      "serviceAccount:${var.sa-cb-email}"
    ]
  }
}
