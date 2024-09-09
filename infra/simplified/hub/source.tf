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

resource "google_secure_source_manager_instance" "source" {
  project     = module.project.id
  location    = var.ssm_region
  instance_id = var.ssm_instance_name
}

resource "random_id" "random" {
  # one byte is represented by 2 hex
  byte_length = 64
}

resource "google_secret_manager_secret" "webhook_trigger" {
  project   = module.project.id
  secret_id = "webhook-trigger"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "webhook_trigger" {
  secret      = google_secret_manager_secret.webhook_trigger.id
  secret_data = random_id.random.hex
}

data "google_iam_policy" "secret_accessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:service-${module.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = google_secret_manager_secret.webhook_trigger.project
  secret_id   = google_secret_manager_secret.webhook_trigger.secret_id
  policy_data = data.google_iam_policy.secret_accessor.policy_data
}
