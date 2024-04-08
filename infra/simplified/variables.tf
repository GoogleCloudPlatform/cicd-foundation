# Copyright 2023-2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "region" {
  description = "Compute region used."
  type        = string
  default     = "europe-north1"
}

variable "zone" {
  description = "Compute zone used."
  type        = string
  default     = "europe-north1-a"
}

variable "project_id" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image"
  type        = string
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

# cf. https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
variable "cluster_release_channel" {
  description = "GKE Release Channel"
  type        = string
  default     = "REGULAR"
}

variable "cluster_deletion_protection" {
  description = "deletion protection for GKE clusters"
  type        = bool
  default     = false
}

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "name of the cluster"
  type        = string
  default     = "gke"
}

variable "developers" {
  description = "Map of developer(s) with their Google Identity used as the key and a map with their GitHub account and (forked) repo to use for the CI/CD OR an empty map in case they use a Cloud Source Repository"
  type = map(object({
    github_user = optional(string, "")
    github_repo = optional(string, "cicd-jumpstart")
  }))
}

variable "apps" {
  description = "List of application names as found within the apps/ folder."
  type        = list(string)
  default = [
    "go-hello-world",
    "java-hello-world",
    "node-hello-world",
    "python-hello-world",
  ]
}

variable "skaffold_image_tag" {
  type        = string
  default     = "v2.10.1"
  description = "Tag of the Skaffold container image"
}

variable "docker_image_tag" {
  type        = string
  default     = "20.10.24"
  description = "Tag of the Docker container image"
}

variable "gcloud_image_tag" {
  type        = string
  default     = "468.0.0"
  description = "Tag of the GCloud container image"
}

variable "git_branch" {
  type        = string
  default     = "^main$"
  description = "Regular expression of which branches the Cloud Build trigger should run."
}

variable "deploy_replicas" {
  description = "Number of replicas per deployment"
  type        = number
  default     = 3
}
