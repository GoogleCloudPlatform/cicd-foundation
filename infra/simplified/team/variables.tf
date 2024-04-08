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

variable "user_identity" {
  type = string
}

variable "team_prefix" {
  type = string
}

variable "github_owner" {
  type        = string
  description = "Owner of the GitHub repo: usually, your GitHub username."
}

variable "github_repo" {
  type        = string
  description = "Name of the (forked) GitHub repository."
}

variable "git_branch" {
  type        = string
  description = "Regular expression of which branches the Cloud Build trigger should run."
}

variable "skaffold_image_tag" {
  type        = string
  description = "Tag of the Skaffold container image"
}

variable "docker_image_tag" {
  type        = string
  description = "Tag of the Docker container image"
}

variable "gcloud_image_tag" {
  type        = string
  description = "Tag of the GCloud container image"
}

variable "apps" {
  description = "List of application names as found within the apps/ folder."
  type        = list(string)
}

variable "region" {
  description = "Compute region used."
  type        = string
}

variable "project_id" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudkms.googleapis.com",
    "monitoring.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containersecurity.googleapis.com"
  ]
}

variable "ws_cluster_id" {
  description = "ID of the Cloud Workstations Cluster"
  type        = string
}

variable "ws_config_id" {
  description = "ID of the Cloud Workstations Config"
  type        = string
}

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image"
  type        = string
}

variable "kritis_note" {
  description = "ID of the kritis note"
  type        = string
}

variable "kms_key_name" {
  description = "Name of the KMS key"
  type        = string
}

variable "kms_digest_alg" {
  description = "KMS Digest Algorithm to be used"
  type        = string
  default     = "SHA512"
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

variable "sa-cb-id" {
  description = "ID of the Cloud Build Service Account"
  type        = string
}

variable "sa-cb-email" {
  description = "Email of the Cloud Build Service Account"
  type        = string
}

variable "sa-cluster-prod-email" {
  description = "Email of the PROD GKE Cluster Service Account"
  type        = string
}
variable "sa-cluster-test-email" {
  description = "Email of the TEST GKE Cluster Service Account"
  type        = string
}
variable "sa-cluster-dev-email" {
  description = "Email of the DEV GKE Cluster Service Account"
  type        = string
}

variable "cd_target_prod" {
  description = "Cloud Deploy Target for PROD"
  type        = string
}

variable "cd_target_test" {
  description = "Cloud Deploy Target for TEST"
  type        = string
}

variable "cd_target_dev" {
  description = "Cloud Deploy Target for DEV"
  type        = string
}

variable "deploy_replicas" {
  description = "Number of replicas per deployment"
  type        = number
}
