# Copyright 2023-2026 Google LLC
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

variable "project_id" {
  type        = string
  description = "Project-ID that references existing project for deploying Cloud Workstations."
}

variable "enable_apis" {
  type        = bool
  description = "Whether to enable the required APIs for the module."
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Common labels to be applied to resources."
  default     = {}
}

variable "cws_service_account_name" {
  type        = string
  description = "Name of the Cloud Workstations Service Account"
  default     = "workstations"
}

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

variable "cws_scopes" {
  type        = list(string)
  description = "The scope of the Cloud Workstations Service Account"
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

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
}
