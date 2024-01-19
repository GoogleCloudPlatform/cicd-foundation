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

variable "project_id" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "ondemandscanning.googleapis.com",
    "orgpolicy.googleapis.com",
    "servicenetworking.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "sa_cb_name" {
  description = "name of Cloud Build Service Account(s)"
  type        = string
  default     = "sa-cloudbuild"
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

variable "developers" {
  description = "list of developers that can create Cloud Workstations"
  type        = list(string)
  default     = []
}

variable "ws_cluster_name" {
  description = "name of the Cloud Workstations cluster"
  type        = string
  default     = "cicd-jumpstart"
}

variable "ws_config_name" {
  description = "name of the Cloud Workstations config"
  type        = string
  default     = "cicd-jumpstart"
}

variable "ws_name" {
  description = "name of the Cloud Workstations instance"
  type        = string
  default     = "cicd-jumpstart"
}

variable "ws_config_machine_type" {
  description = "machine type of Cloud Workstations instance"
  type        = string
  default     = "e2-standard-4"
}

variable "ws_config_boot_disk_size_gb" {
  description = "disk size of Cloud Workstations instance"
  type        = number
  default     = 35
}

variable "ws_config_disable_public_ip" {
  description = "private Cloud Workstations instance?"
  type        = bool
  default     = true
}

variable "cluster-prod_network_config" {
  description = "Cluster network configuration."
  type = object({
    nodes_cidr_block              = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block    = "10.76.0.0/22"
    pods_cidr_block     = "172.19.0.0/19"
    services_cidr_block = "192.168.12.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
    }
    master_cidr_block = "10.1.11.0/28"
  }
}

variable "cluster-test_network_config" {
  description = "Cluster network configuration."
  type = object({
    nodes_cidr_block              = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block    = "10.75.0.0/22"
    pods_cidr_block     = "172.18.0.0/19"
    services_cidr_block = "192.168.8.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
    }
    master_cidr_block = "10.1.10.0/28"
  }
}

variable "cluster-dev_network_config" {
  description = "Cluster network configuration."
  type = object({
    nodes_cidr_block              = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block    = "10.73.0.0/22"
    pods_cidr_block     = "172.16.0.0/19"
    services_cidr_block = "192.168.0.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
      # permit access to public endpoint, e.g., to kubectl from CloudShell
      external = "0.0.0.0/0"
    }
    master_cidr_block = "10.1.8.0/28"
  }
}

variable "nat_name" {
  description = "name of the CloudNAT instance"
  type        = string
  default     = "nat"
}

variable "vpc-hub_primary_cidr" {
  description = "CIDR for the primary subnet in the hub VPC"
  type        = string
  default     = "10.8.0.0/22"
}

variable "vpc-hub_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.60.0.0/16"
}

variable "vpc-prod_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.63.0.0/16"
}

variable "vpc-prod-build_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.66.0.0/16"
}

variable "vpc-prod-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC"
  type        = string
  default     = "10.79.0.0/22"
}

variable "vpc-test_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.64.0.0/16"
}

variable "vpc-test-build_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.67.0.0/16"
}

variable "vpc-test-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC"
  type        = string
  default     = "10.78.0.0/22"
}

variable "vpc-dev_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.65.0.0/16"
}

variable "vpc-dev-build_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.62.0.0/16"
}

variable "vpc-dev-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC"
  type        = string
  default     = "10.77.0.0/22"
}

variable "vpc_create" {
  description = "Flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}
