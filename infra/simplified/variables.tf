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

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "developers" {
  type = map(object({
    github_user = string
    github_repo = string
  }))
}

variable "github_owner" {
  type        = string
  default     = "GoogleCloudPlaform"
  description = "Owner of the GitHub repo: usually, your GitHub username."
}

variable "github_repo_name" {
  type        = string
  default     = "professional-services"
  description = "Name of the GitHub repository."
}

variable "github_branch" {
  type        = string
  default     = "^main$"
  description = "Regular expression of which branches the Cloud Build trigger should run. Defaults to all branches."
}
