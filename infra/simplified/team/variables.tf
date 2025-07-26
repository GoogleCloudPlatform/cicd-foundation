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
  description = "The identifier of the developer."
  type        = string
}

variable "team" {
  description = "The identifier of a team (developer) used as a prefix for resources."
  type        = string
}

variable "ssm_instance_name" {
  description = "Name of the Secure Source Manager instance."
  type        = string
}

variable "ssm_region" {
  description = "Region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations"
  type        = string
}

variable "webhook_trigger_secret" {
  description = "The secret for the webhook trigger."
  type        = string
}

variable "github_owner" {
  description = "Owner of the GitHub repo: usually, your GitHub username."
  type        = string
}

variable "github_repo" {
  description = "Name of the (forked) GitHub repository."
  type        = string
}

variable "git_branch_trigger" {
  description = "Branch used for the Cloud Build trigger. Used by Secure Source Manager (SSM) and Cloud Scheduler."
  type        = string
}

variable "git_branch_trigger_regexp" {
  description = "Regular expression for the Cloud Build trigger. Not used by Secure Source Manager (SSM)."
  type        = string
}

variable "skaffold_quiet" {
  description = "suppress Skaffold output"
  type        = bool
  default     = false
}

variable "skaffold_output" {
  description = "the artifacts json output filename from skaffold"
  type        = string
  default     = "artifacts.json"
}

variable "skaffold_image_tag" {
  description = "Tag of the Skaffold container image"
  type        = string
}

variable "docker_image_tag" {
  description = "Tag of the Docker container image"
  type        = string
}

variable "gcloud_image_tag" {
  description = "Tag of the GCloud container image"
  type        = string
}

variable "policy_file" {
  description = "path of the policy file within the repository"
  type        = string
  default     = "./tools/kritis/vulnz-signing-policy.yaml"
}

variable "runtimes" {
  description = "List of runtime solutions."
  type        = list(string)
}

variable "stages" {
  description = "List of deployment stages."
  type        = list(string)
}

variable "build_machine_type_default" {
  description = "the default machine type to use for Cloud Build build, cf. https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds#machinetype"
  type        = string
}

variable "build_timeout_default" {
  description = "the default timeout in seconds for the Cloud Build build step"
  type        = number
}

variable "apps" {
  description = "Map of applications as found within the apps/ folder, their build configuration, runtime, deployment stages and parameters."
  type = map(object({
    build = optional(object({
      timeout      = number
      machine_type = string
      })
    )
    runtime = optional(string, "cloudrun")
    stages  = optional(map(map(string)))
  }))
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
}

variable "sa-ws-email" {
  description = "Email of the Cloud Workstations Service Account"
  type        = string
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
