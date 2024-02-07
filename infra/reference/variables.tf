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

# gcloud organizations describe $ORG_NAME --format="value(name.segment(1))"
variable "org_id" {
  description = "Organization-ID that references existing organization."
  type        = number
}

variable "folder_hub_id" {
  description = "Folder-ID that references existing Hub folder."
  type        = number
}

variable "folder_prod_id" {
  description = "Folder-ID that references existing Production folder."
  type        = number
}

variable "folder_test_id" {
  description = "Folder-ID that references existing Testing folder."
  type        = number
}

variable "folder_dev_id" {
  description = "Organization-ID that references existing Development folder."
  type        = number
}

variable "folders_create" {
  description = "Create folders instead of using existing ones."
  type        = bool
  default     = false
}

variable "project_hub_host" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_hub_supplychain" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_prod_host" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_prod_supplychain" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_prod_service" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_test_host" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_test_supplychain" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_test_service" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_dev_host" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_dev_supplychain" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "project_dev_service" {
  description = "Project-ID that references existing project."
  type        = string
}

variable "projects_create" {
  description = "Create projects instead of using an existing ones."
  type        = bool
  default     = false
}

variable "project_hub_host_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "project_hub_supplychain_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudkms.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "compute.googleapis.com",
    "ondemandscanning.googleapis.com",
    "orgpolicy.googleapis.com",
    "sourcerepo.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "project_prod_host_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_prod_supplychain_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "orgpolicy.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_prod_service_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "project_test_host_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_test_supplychain_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "orgpolicy.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_test_service_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "project_dev_host_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    # "gkeconnect.googleapis.com",
    # "servicedirectory.googleapis.com",
    # "gkehub.googleapis.com",
    # "cloudresourcemanager.googleapis.com",
    # "iam.googleapis.com",
    # "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_dev_supplychain_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "orgpolicy.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_dev_service_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "region" {
  description = "Compute region used."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Compute zone used."
  type        = string
  default     = "us-central1-a"
}

variable "vpc_create" {
  description = "Flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}

variable "vpc_subnet_name" {
  description = "name of the subnet hosting the cluster"
  type        = string
  nullable    = false
  default     = "primary"
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

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

variable "nat_name" {
  description = "name of the CloudNAT instance"
  type        = string
  default     = "nat"
}

# cf. https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
variable "cluster_release_channel" {
  description = "GKE Release Channel"
  type        = string
  default     = "REGULAR"
}

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
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

variable "deploy_replicas" {
  description = "number of replicas per deployment"
  type        = number
  default     = 3
}

variable "developers" {
  description = "list of developers, e.g., to create Cloud Workstations"
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

variable "github_owner" {
  type        = string
  default     = "GoogleCloudPlaform"
  description = "Owner of the GitHub repo."
}

variable "github_repo" {
  type        = string
  default     = "cicd-jumpstart"
  description = "Name of the GitHub repository."
}

variable "git_branch" {
  type        = string
  default     = "^main$"
  description = "Regular expression of which branches the Cloud Build trigger should run."
}

variable "cb_pool_name" {
  description = "name of the Cloud Build worker pool"
  type        = string
  default     = "default"
}

variable "cb_pool_disk_size_gb" {
  description = "disk size of a Cloud Build worker"
  type        = number
  default     = 100
}

variable "cb_pool_machine_type" {
  description = "machine type of a Cloud Build worker"
  type        = string
  default     = "e2-standard-4"
}

variable "sa_cb_name" {
  description = "name of Cloud Build Service Account(s)"
  type        = string
  default     = "sa-cloudbuild"
}

variable "sa_cd_name" {
  description = "name of the Cloud Deploy Service Account"
  type        = string
  default     = "sa-cloudeploy"
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
