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

# General Project & Naming

variable "enable_apis" {
  type        = bool
  description = "Whether to enable the required APIs for the module."
  default     = true
}

variable "project_id" {
  type        = string
  description = "Project-ID that references existing project."
}

# Location/Region Variables

# go/keep-sorted start block=yes newline_separated=yes
variable "artifact_registry_region" {
  type        = string
  description = "The region for Artifact Registry."
  default     = "us-central1"
}

variable "cloud_build_region" {
  type        = string
  description = "The region for Cloud Build."
  default     = "us-central1"
}

variable "scheduler_default_region" {
  type        = string
  description = "The default region for the Cloud Scheduler if not specified in the application config."
  default     = "us-central1"
}

variable "secret_manager_region" {
  type        = string
  description = "The region for Secret Manager."
  default     = "us-central1"
}

variable "secure_source_manager_region" {
  type        = string
  description = "The region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations."
  default     = "us-central1"
}

variable "vpc_region" {
  type        = string
  description = "Compute region used for VPC and other related resources."
  default     = "us-central1"
}
# go/keep-sorted end

# Networking

# go/keep-sorted start block=yes newline_separated=yes
variable "create_cloud_nat" {
  type        = bool
  description = <<-EOT
    Controls the deployment of Cloud NAT for the VPC.
    - If set to 'true', Cloud NAT is always created.
    - If set to 'false', Cloud NAT is never created.
    - If set to 'null' (default), Cloud NAT is automatically created only if at least one workstation configuration is set to be private (disable_public_ip_addresses = true).
  EOT
  default     = null
}

variable "create_vpc" {
  type        = bool
  description = "Flag indicating whether the VPC should be created or not."
  default     = true
}

variable "psa_cidr" {
  type        = string
  description = "PSA CIDR range"
  default     = "10.60.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR for the primary subnet in the VPC"
  default     = "10.8.0.0/16"
}

variable "subnet_name" {
  type        = string
  description = "Name of the Virtual Private Cloud (VPC) network for the workstation in a region."
  default     = "primary"
}

variable "vpc_name" {
  type        = string
  description = "Name of the Virtual Private Cloud (VPC) network for the workstation."
  default     = "workstations"
}
# go/keep-sorted end

# Source Control (GitHub & Secure Source Manager)

# go/keep-sorted start block=yes newline_separated=yes
variable "git_branch_trigger" {
  type        = string
  description = "The Secure Source Manager (SSM) branch that triggers Cloud Build on push."
  default     = "main"
}

variable "git_branches_regexp_trigger" {
  type        = string
  description = "A regular expression to match GitHub branches that trigger Cloud Build on push."
  default     = "^main$"
}

variable "github_owner" {
  type        = string
  description = "The owner of the GitHub repository (user or organization)."
  default     = null
}

variable "github_repo" {
  type        = string
  description = "The name of the GitHub repository."
  default     = null
}

variable "secure_source_manager_always_create" {
  type        = bool
  description = "If true, create Secure Source Manager resources (instance, repository). These resources can be created even when a GitHub repository is also specified as the trigger source."
  default     = false
}

variable "secure_source_manager_deletion_policy" {
  type        = string
  description = "The deletion policy for the Secure Source Manager instance and repository. One of DELETE, PREVENT, or ABANDON."
  default     = "PREVENT"
}

variable "secure_source_manager_instance_id" {
  type        = string
  description = "The full ID of an existing Secure Source Manager instance. If null, a new one will be created."
  default     = null
}

variable "secure_source_manager_instance_name" {
  type        = string
  description = "The name of the Secure Source Manager instance."
  default     = "cicd-foundation"
}

variable "secure_source_manager_repo_git_url_to_clone" {
  type        = string
  description = "The URL of a Git repository to clone into the new Secure Source Manager repository. If null, cloning is skipped."
  default     = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
}

variable "secure_source_manager_repo_name" {
  type        = string
  description = "The name of the Secure Source Manager repository."
  default     = "cicd-foundation"
}
# go/keep-sorted end

# Cloud Workstations

variable "boot_disk_size_gb_default" {
  type        = number
  description = "The default boot disk size in GB for Cloud Workstation instances."
  default     = 100
}

variable "disable_public_ip_addresses_default" {
  type        = bool
  description = "The default for disabling public IP addresses for Cloud Workstation instances."
  default     = false
}

variable "enable_nested_virtualization_default" {
  type        = bool
  description = "The default for enabling nested virtualization for Cloud Workstation instances."
  default     = true
}

variable "idle_timeout_seconds_default" {
  type        = number
  description = "The default idle timeout in seconds for Cloud Workstation instances."
  default     = 3600
}

variable "machine_type_default" {
  type        = string
  description = "The default machine type for Cloud Workstation instances."
  default     = "n1-standard-96"
}

variable "pool_size_default" {
  type        = number
  description = "The default pool size for Cloud Workstation instances."
  default     = 0
}

variable "persistent_disk_reclaim_policy_default" {
  type        = string
  description = "The default reclaim policy for Cloud Workstation persistent disks."
  default     = "RETAIN"
}

variable "persistent_disk_fs_type_default" {
  type        = string
  description = "The default filesystem type for Cloud Workstation persistent disks."
  default     = "ext4"
}

variable "persistent_disk_type_default" {
  type        = string
  description = "The default disk type for Cloud Workstation persistent disks."
  default     = "pd-balanced"
}

# Cloud Build

# go/keep-sorted start block=yes newline_separated=yes
variable "build_machine_type_default" {
  type        = string
  description = "The default machine type to use for Cloud Build jobs."
  default     = "UNSPECIFIED"
}

variable "build_timeout_default_seconds" {
  type        = number
  description = "The default timeout in seconds for Cloud Build jobs."
  default     = 7200
}
# go/keep-sorted end

# Cloud Workstations Custom Images

variable "cws_custom_images" {
  type = map(object({
    build = optional(object({
      skaffold_path   = optional(string)
      timeout_seconds = optional(number)
      machine_type    = optional(string)
      env             = optional(map(string), {})
      })
    )
    workstation_config = optional(object({
      scheduler_region = optional(string)
      ci_schedule      = optional(string)
      paused           = optional(bool, false)
    })),
    git_repo = optional(object({
      url    = string
      branch = string
    })),
    github = optional(object({
      owner          = string
      repo           = string
      branch_pattern = string
    })),
    ssm = optional(object({
      instance_id = string
      repo_name   = string
      branch      = string
    }))
  }))
  description = <<-EOT
    Map of applications as found within the apps/ folder of the repository,
    their build configuration, runtime, deployment stages and parameters.
  EOT
  validation {
    condition = alltrue([
      for k, v in var.cws_custom_images : sum([v.github != null ? 1 : 0, v.ssm != null ? 1 : 0, v.git_repo != null ? 1 : 0]) <= 1
    ])
    error_message = "A custom image can specify at most one source: github, ssm, or git_repo."
  }
  default = {
    // go/keep-sorted start block=yes
    "android-studio-for-platform" : {
      git_repo = {
        url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
        branch = "main"
      }
      build = {
        skaffold_path   = "apps/workstations/android-studio-for-platform"
        timeout_seconds = 7200
        machine_type    = "E2_HIGHCPU_32"
        env = {
        }
      }
    },
    "antigravity" : {
      git_repo = {
        url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
        branch = "main"
      }
      build = {
        skaffold_path   = "apps/workstations/antigravity"
        timeout_seconds = 7200
        machine_type    = "E2_HIGHCPU_32"
        env = {
        }
      }
    },
    // go/keep-sorted end
  }
}

# Cloud Workstations Clusters

variable "cws_clusters" {
  type = map(object({
    network     = string
    region      = string
    subnetwork  = string
    vpc_project = optional(string)
    domain_config = optional(object({
      domain = string
    }))
    private_cluster_config = optional(object({
      enable_private_endpoint = optional(bool, false)
    }))
  }))
  description = "A map of Cloud Workstation clusters to create. The key of the map is used as the unique ID for the cluster."
  default     = {}
}

# Cloud Workstations Configs and instances

variable "cws_configs" {
  type = map(object({
    accelerators = optional(list(object({
      type  = string
      count = number
    })), [])
    boost_configs = optional(list(object({
      id = string
      accelerators = optional(list(object({
        type  = string
        count = number
      })), [])
      boot_disk_size_gb            = optional(number)
      enable_nested_virtualization = optional(bool)
      machine_type                 = optional(string)
      pool_size                    = optional(number)
    })), [])
    boot_disk_size_gb            = optional(number)
    creators                     = optional(list(string))
    custom_image_names           = optional(list(string), [])
    cws_cluster                  = string
    disable_public_ip_addresses  = optional(bool)
    display_name                 = optional(string)
    enable_nested_virtualization = optional(bool)
    idle_timeout_seconds         = optional(number)
    image                        = optional(string)
    instances = optional(list(object({
      name         = string
      display_name = optional(string)
      users        = list(string)
    })))
    machine_type                    = optional(string)
    persistent_disk_fs_type         = optional(string)
    persistent_disk_reclaim_policy  = optional(string)
    persistent_disk_size_gb         = optional(number)
    persistent_disk_source_snapshot = optional(string)
    persistent_disk_type            = optional(string)
    pool_size                       = optional(number)
    shielded_instance_config = optional(object({
      enable_secure_boot          = optional(bool, true)
      enable_vtpm                 = optional(bool, true)
      enable_integrity_monitoring = optional(bool, true)
    }), null)
  }))
  description = "A map of Cloud Workstation configurations."
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.cws_configs :
      v.persistent_disk_source_snapshot == null || v.persistent_disk_size_gb == null
    ])
    error_message = "If persistent_disk_source_snapshot is provided, persistent_disk_size_gb must not be set."
  }
  validation {
    condition = alltrue([
      for k, v in var.cws_configs :
      v.persistent_disk_source_snapshot != null || v.persistent_disk_size_gb != null
    ])
    error_message = "If persistent_disk_source_snapshot is not provided, persistent_disk_size_gb must be set."
  }
  validation {
    condition = alltrue([
      for k, v in var.cws_configs : v.image == null || length(coalesce(v.custom_image_names, [])) == 0
    ])
    error_message = "image and custom_image_names are mutually exclusive and cannot be set at the same time."
  }
  validation {
    condition = alltrue([
      for k, v in var.cws_configs : alltrue([
        for name in coalesce(v.custom_image_names, []) : contains(keys(var.cws_custom_images), name)
      ])
    ])
    error_message = "If custom_image_names is provided, all names must be keys in the cws_custom_images map."
  }
}

## Android Platform Development

variable "android_branches" {
  type        = list(string)
  description = "Android branches to build"
  default     = []
}

variable "android_targets" {
  type        = map(string)
  description = <<-EOT
    Android `lunch` targets to build.
    The keys of this maps are used for the names of the Workstation Configs.
    The values are the actual lunch targets.
  EOT
  default     = {}
}
