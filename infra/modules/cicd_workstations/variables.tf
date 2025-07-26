# Copyright 2023-2025 Google LLC
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

variable "cws_service_account_name" {
  type        = string
  description = "Name of the Cloud Workstations Service Account"
  default     = "workstations"
}

variable "cws_scopes" {
  type        = list(string)
  description = "The scope of the Cloud Workstations Service Account"
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "cws_clusters" {
  type = map(object({
    network    = string
    region     = string
    subnetwork = string
  }))
  description = "A map of Cloud Workstation clusters to create. The key of the map is used as the unique ID for the cluster."
  default     = {}
}

variable "cws_configs" {
  type = map(object({
    cws_cluster                    = string
    idle_timeout                   = number
    machine_type                   = string
    boot_disk_size_gb              = number
    disable_public_ip_addresses    = bool
    pool_size                      = number
    enable_nested_virtualization   = bool
    persistent_disk_size_gb        = number
    persistent_disk_fs_type        = string
    persistent_disk_type           = string
    persistent_disk_reclaim_policy = string
    image                          = optional(string)
    creators                       = optional(list(string))
    instances = optional(list(object({
      name  = string
      users = list(string)
    })))
  }))
  description = "A map of Cloud Workstation configurations."
  default     = {}
}

variable "cloud_build_service_account_id" {
  type        = string
  description = "The ID of the Cloud Build Service Account to use for triggering the build of the Cloud Workstations custom images."
  validation {
    condition     = length(var.custom_images) == 0 || var.cloud_build_service_account_id != ""
    error_message = "The cloud_build_service_account_id is required when custom_images are provided."
  }
  default = ""
}

variable "custom_images" {
  type = map(object({
    scheduler_region = optional(string)
    ci_schedule      = optional(string)
    ci_trigger = object({
      project  = string
      location = string
      id       = string
    })
  }))
  description = "Map of custom images and their Cloud Build trigger details to be used for Cloud Workstations. The key of the map equals the container image name."
  default     = {}
}

variable "custom_images_schedule_suffix" {
  type        = string
  description = "Suffix to be added to the Cloud Scheduler job name for triggering the build of the Cloud Workstations custom images."
  default     = "-nightly"
}

variable "default_custom_images_schedule" {
  type        = string
  description = "Default cron schedule for triggering the build of the Cloud Workstations custom images."
  default     = "0 1 * * *"
}

variable "default_custom_images_schedule_region" {
  type        = string
  description = "Default region for the Cloud Scheduler job for triggering the build of the Cloud Workstations custom images."
  default     = "us-central1"
}
