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

module "docker_artifact_registry" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/artifact-registry?ref=v28.0.0"
  project_id = var.project_id
  name       = "${var.team-prefix}-${var.registry_id}"
  location   = var.region
  format = {
    docker = {}
  }
  iam = {
    "roles/artifactregistry.reader" = [
      module.sa-cluster-prod.iam_email,
      module.sa-cluster-test.iam_email,
      module.sa-cluster-dev.iam_email,
      "serviceAccount:${var.sa-cb-email}"
    ],
    "roles/artifactregistry.writer" = [
      "serviceAccount:${var.sa-cb-email}"
    ]
  }
}
