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

variable "team-prefix" {
  type    = string
  default = "team1"
}

variable "github_owner" {
  type        = any
  description = "Owner of the GitHub repo: usually, your GitHub username."
}

variable "github_repo" {
  type        = any
  description = "Name of the GitHub repository."
}

variable "github_branch" {
  type        = string
  default     = "^main$"
  description = "Regular expression of which branches the Cloud Build trigger should run."
}

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

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
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

variable "cluster_name" {
  description = "name of the cluster"
  type        = string
  default     = "eu"
}

variable "sa_cluster_name" {
  description = "name of GKE Service Account(s)"
  type        = string
  default     = "sa-gke"
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

variable "deploy_replicas" {
  description = "number of replicas per deployment"
  type        = number
  default     = 3
}

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image"
  type        = string
}

variable "kms_digest_alg" {
  description = "KMS Digest Algorithm to be used"
  type        = string
  default     = "SHA512"
}

variable "sa_cd_name" {
  description = "name of the Cloud Deploy Service Account"
  type        = string
  default     = "sa-cloudeploy"
}

variable "sa-cb-email" {
  description = "email of the Cloud Build Service Account"
  type        = string
}
variable "sa-cb-id" {
  description = "id of the Cloud Build Service Account"
  type        = string
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

variable "cloud_deploy_robot_sa_email" {
  description = "Email of the hubs cloud deploy robot sa."
  type        = string
}

variable "cloud_build_robot_sa_email" {
  description = "Email of the hubs cloud build robot sa."
  type        = string
}

variable "vpc_self_link" {
  type = string
}

variable "vpc_hub_subnet_self_link" {
  type = string
}

variable "vpc_dev_subnet_self_link" {
  type = string
}

variable "vpc_test_subnet_self_link" {
  type = string
}

variable "vpc_prod_subnet_self_link" {
  type = string
}
