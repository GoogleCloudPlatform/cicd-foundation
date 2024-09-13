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
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "securesourcemanager.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "sa_cb_name" {
  description = "name of Cloud Build Service Account(s)"
  type        = string
  default     = "sa-cloudbuild"
}

variable "sa_cd_name" {
  description = "Name of the Cloud Deploy Service Account"
  type        = string
  default     = "sa-clouddeploy"
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
}

variable "developers" {
  description = "list of developers that can create Cloud Workstations"
  type        = list(string)
  default     = []
}

variable "vpc_create" {
  description = "Flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}

variable "vpc-hub_primary_cidr" {
  description = "CIDR for the primary subnet in the hub VPC"
  type        = string
  default     = "10.8.0.0/16"
}

variable "vpc-hub_psa_cidr" {
  description = "PSA CIDR range"
  type        = string
  default     = "10.60.0.0/16"
}

variable "proxy_only_subnet_cidr_block" {
  description = "IP range for the proxy-only subnet"
  type        = string
  default     = "10.127.0.0/16"
}

variable "ssm_instance_name" {
  description = "name of the Secure Source Manager instance"
  type        = string
  default     = "cicd-foundation"
}

variable "ssm_region" {
  description = "region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations"
  type        = string
  default     = "europe-west4"
}

variable "sa_ws_name" {
  description = "name of the Cloud Workstations Service Account"
  type        = string
  default     = "sa-workstations"
}

variable "ws_cluster_name" {
  description = "name of the Cloud Workstations cluster"
  type        = string
  default     = "cicd-foundation"
}

variable "ws_config_name" {
  description = "name of the Cloud Workstations config"
  type        = string
  default     = "cicd-foundation"
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
  default     = "e2-standard-4"
}

variable "ws_config_boot_disk_size_gb" {
  description = "disk size of Cloud Workstations instance"
  type        = number
  default     = 35
}

variable "ws_nested_virtualization" {
  description = "nested virtualization to be enabled for Workstations?"
  type        = bool
  default     = false
}
variable "ws_pd_disk_size_gb" {
  description = "disk size of Cloud Workstations mounted persistent disk"
  type        = number
  default     = 200
}

variable "ws_pd_disk_fs_type" {
  description = "filesystem type of the Cloud Workstations persistent disk"
  type        = string
  default     = "ext4"
}

variable "ws_pd_disk_type" {
  description = "disk type of the Cloud Workstations persistent disk"
  type        = string
  default     = "pd-standard"
}

variable "ws_pd_disk_reclaim_policy" {
  description = "reclaim policy of the Cloud Workstations persistent disk"
  type        = string
  default     = "DELETE"
}

variable "ws_config_disable_public_ip" {
  description = "private Cloud Workstations instance?"
  type        = bool
  default     = true
}

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image"
  type        = string
}

variable "vulnz_attestor_name" {
  description = "Name of the Binary Authentication Attestor; also used for the Container Analysis note"
  type        = string
  default     = "vulnz-attestor"
}

variable "kms_key_name" {
  description = "Name of the KMS key"
  type        = string
  default     = "vulnz-attestor-key"
}

variable "kms_keyring_name" {
  description = "Name of the KMS keyring"
  type        = string
  default     = "vulnz-attestor-keyring"
}

variable "kms_digest_alg" {
  description = "KMS Digest Algorithm to be used"
  type        = string
  default     = "SHA512"
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
      # permit access to public endpoint, e.g., to kubectl from CloudShell
      external = "0.0.0.0/0"
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
      # permit access to public endpoint, e.g., to kubectl from CloudShell
      external = "0.0.0.0/0"
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

variable "cluster_deletion_protection" {
  description = "deletion protection for GKE clusters"
  type        = bool
  default     = true
}

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "name of the cluster"
  type        = string
}

# cf. https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
variable "cluster_release_channel" {
  description = "GKE Release Channel"
  type        = string
  default     = "REGULAR"
}

variable "cluster_roles" {
  description = "GKE Service Account roles"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ]
}

variable "sa_cluster_name" {
  description = "name of GKE Service Account(s)"
  type        = string
  default     = "sa-gke"
}

variable "nat_name" {
  description = "name of the CloudNAT instance"
  type        = string
  default     = "nat"
}
