# Copyright 2024-2025 Google LLC
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
  default     = "us-west1"
}

variable "project_id" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

variable "admins" {
  description = "Google Identities of the Cloud Workstation admins"
  type        = list(string)
  default     = []
}

variable "users" {
  description = "Google Identities of the Cloud Workstation user"
  type        = list(string)
  default     = []
}

variable "github_owner" {
  description = "Owner of the GitHub repo: usually, your GitHub username."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "Name of the (forked) GitHub repository."
  type        = string
  default     = ""
}

variable "ssm_instance_name" {
  description = "name of the Secure Source Manager instance"
  type        = string
  default     = "workstation-images"
}

variable "repo_name" {
  description = "name of the Git repository"
  type        = string
  default     = "aosp"
}

variable "git_branch_trigger" {
  description = "Branch used for the Cloud Build trigger. Used by Secure Source Manager (SSM) and Cloud Scheduler."
  type        = string
  default     = "main"
}

variable "git_branch_trigger_regexp" {
  description = "Regular expression for the Cloud Build trigger. Not used by Secure Source Manager (SSM)."
  type        = string
  default     = "^main$"
}

variable "skaffold_output" {
  description = "the artifacts json output filename from skaffold"
  type        = string
  default     = "artifacts.json"
}

variable "skaffold_quiet" {
  description = "suppress Skaffold output"
  type        = bool
  default     = false
}

variable "skaffold_image_tag" {
  description = "Tag of the Skaffold container image"
  type        = string
  default     = "v2.13.2-lts"
}

variable "docker_image_tag" {
  description = "Tag of the Docker container image"
  type        = string
  default     = "20.10.24"
}

variable "build_timeout_default" {
  description = "the default timeout in seconds for the Cloud Build build step"
  type        = number
  default     = 7200
}

variable "build_machine_type_default" {
  description = "the default machine type to use for Cloud Build build"
  type        = string
  default     = "UNSPECIFIED"
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
  default = {
    "asfp" : {
      build = {
        timeout      = 7200
        machine_type = "E2_HIGHCPU_32"
      }
      runtime = "workstation"
    },
    "asfp-ubuntu22" : {
      build = {
        timeout      = 7200
        machine_type = "E2_HIGHCPU_32"
      }
      runtime = "workstation"
    }
  }
}

variable "project_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "sa_cb_name" {
  description = "name of Cloud Build Service Account(s)"
  type        = string
  default     = "sa-cloudbuild"
}

variable "vpc_name" {
  description = "Name of the Virtual Private Cloud (VPC) network for the workstation."
  type        = string
  default     = "workstations"
}

variable "vpc_create" {
  description = "Flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}

variable "subnet_name" {
  description = "Name of the Virtual Private Cloud (VPC) network for the workstation in a region."
  type        = string
  default     = "primary"
}

variable "subnet_cidr" {
  description = "CIDR for the primary subnet in the VPC"
  type        = string
  default     = "10.8.0.0/16"
}

variable "psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.60.0.0/16"
}

variable "sa_ws_name" {
  description = "name of the Cloud Workstations Service Account"
  type        = string
  default     = "sa-workstations"
}

variable "ws_cluster_name" {
  description = "name of the Cloud Workstations cluster"
  type        = string
  default     = "cluster"
}

variable "ws_config_name_default" {
  description = "name of the default Cloud Workstations config"
  type        = string
  default     = "asfp"
}

variable "ws_pool_size" {
  description = "Cloud Workstations pool size (to speed up startup time)"
  type        = number
  default     = 1
}

variable "ws_idle_time" {
  description = "Cloud Workstations idle timeout in seconds"
  type        = number
  default     = 1800
}

variable "ws_config_machine_type" {
  description = "machine type of Cloud Workstations instance"
  type        = string
  default     = "n1-standard-96"
}

variable "ws_config_boot_disk_size_gb" {
  description = "disk size of Cloud Workstations instance"
  type        = number
  default     = 35
}

variable "ws_nested_virtualization" {
  description = "nested virtualization to be enabled for Workstations?"
  type        = bool
  default     = true
}

variable "ws_image_tag" {
  description = "the container image tag for the Cloud Workstation"
  type        = string
  default     = "latest"
}

variable "ws_pd_disk_size_gb" {
  description = "disk size of Cloud Workstations mounted persistent disk"
  type        = number
  default     = 1000
}

variable "ws_pd_disk_type" {
  description = "disk type of the Cloud Workstations persistent disk"
  type        = string
  default     = "pd-ssd"
}

variable "ws_pd_disk_fs_type" {
  description = "filesystem type of the Cloud Workstations persistent disk"
  type        = string
  default     = "ext4"
}

variable "ws_pd_disk_reclaim_policy" {
  description = "reclaim policy of the Cloud Workstations persistent disk"
  type        = string
  default     = "RETAIN"
}

variable "ws_pd_disk_snapshot_id" {
  description = "Disk snapshot to use for Cloud Workstations"
  type        = string
}

variable "ws_config_disable_public_ip" {
  description = "private Cloud Workstations instance?"
  type        = bool
  default     = true
}

variable "aosp_branches" {
  description = "Android Open Source Project branches to build"
  type        = list(string)
  default     = []
}

variable "aosp_targets" {
  description = "Android Open Source Project targets to build. The keys of this maps are used for the names of the Workstation Configs. The values are the actual lunch targets."
  type        = map(string)
  default     = {}
}
