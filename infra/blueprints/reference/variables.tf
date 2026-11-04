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

# go/keep-sorted start block=yes newline_separated=yes
variable "apps" {
  description = "Map of applications to be deployed."
  type = map(object({
    build = optional(object({
      skaffold_path   = optional(string)
      timeout_seconds = optional(number)
      machine_type    = optional(string)
      env             = optional(map(string), {})
      included_files  = optional(list(string), [])
    }))
    runtime = optional(string)
    stages  = optional(map(map(string)))
    git_repo = optional(object({
      url    = string
      branch = string
    }))
    github = optional(object({
      owner          = string
      repo           = string
      branch_pattern = string
    }))
    ssm = optional(object({
      instance_id = string
      repo_name   = string
      branch      = string
    }))
    agents = optional(map(map(object({
      enabled       = optional(bool, false)
      model         = optional(string)
      location      = optional(string)
      personas      = optional(list(string))
      instructions  = optional(string)
      prompt        = optional(string)
      allow_failure = optional(bool, true)
    }))), {})
  }))
  default = {
    "go-hello-world" = {
      runtime = "gke"
      stages = {
        "dev"  = { "replicas" = 1 }
        "test" = { "replicas" = 3 }
        "prod" = { "replicas" = 3 }
      }
    }
    "java-hello-world" = {
      runtime = "cloudrun"
      stages = {
        "dev"  = { "replicas" = 1 }
        "test" = { "replicas" = 3 }
        "prod" = { "replicas" = 3 }
      }
    }
    "node-hello-world" = {
      runtime = "gke"
      stages = {
        "dev"  = { "replicas" = 1 }
        "test" = { "replicas" = 3 }
        "prod" = { "replicas" = 3 }
      }
    }
    "python-hello-world" = {
      runtime = "gke"
      stages = {
        "dev"  = { "replicas" = 1 }
        "test" = { "replicas" = 3 }
        "prod" = { "replicas" = 3 }
      }
    }
  }
}

variable "artifact_registry_region" {
  description = "The region for Artifact Registry. If null, defaults to region."
  type        = string
  default     = null
}

variable "boot_disk_size_gb_default" {
  description = "The default boot disk size in GB for Cloud Workstation instances."
  type        = number
  default     = 35
}

variable "build_machine_type_default" {
  description = "The default machine type to use for Cloud Build jobs."
  type        = string
  default     = "UNSPECIFIED"
}

variable "build_source_retention_days" {
  description = "The number of days to retain Cloud Build source archives in the GCS staging bucket before deletion."
  type        = number
  default     = 7
}

variable "build_timeout_default" {
  description = "The default timeout in seconds for Cloud Build jobs."
  type        = number
  default     = 7200
}

variable "canary_route_update_wait_time_seconds" {
  description = "Wait time in seconds for GKE Gateway Service Mesh route updates during canary deployments."
  type        = number
  default     = 120
}

variable "cb_pool_disk_size_gb" {
  description = "Disk size in GB of each Cloud Build worker."
  type        = number
  default     = 100
}

variable "cb_pool_machine_type" {
  description = "Machine type of each Cloud Build worker."
  type        = string
  default     = "e2-standard-4"
}

variable "cb_pool_name" {
  description = "Base name of the Cloud Build private worker pools."
  type        = string
  default     = "default"
}

variable "cloud_build_region" {
  description = "The region for Cloud Build. If null, defaults to region."
  type        = string
  default     = null
}

variable "cluster-dev_network_config" {
  description = "Cluster dev network configuration."
  type = object({
    nodes_cidr_block              = string
    proxy_only_subnet_cidr_block  = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block             = "10.73.0.0/22"
    proxy_only_subnet_cidr_block = "10.73.128.0/22"
    pods_cidr_block              = "172.16.0.0/19"
    services_cidr_block          = "192.168.0.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
      external = "0.0.0.0/0"
    }
    master_cidr_block = "10.1.8.0/28"
  }
}

variable "cluster-prod_network_config" {
  description = "Cluster prod network configuration."
  type = object({
    nodes_cidr_block              = string
    proxy_only_subnet_cidr_block  = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block             = "10.76.0.0/22"
    proxy_only_subnet_cidr_block = "10.76.128.0/22"
    pods_cidr_block              = "172.19.0.0/19"
    services_cidr_block          = "192.168.12.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
    }
    master_cidr_block = "10.1.11.0/28"
  }
}

variable "cluster-test_network_config" {
  description = "Cluster test network configuration."
  type = object({
    nodes_cidr_block              = string
    proxy_only_subnet_cidr_block  = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block             = "10.75.0.0/22"
    proxy_only_subnet_cidr_block = "10.75.128.0/22"
    pods_cidr_block              = "172.18.0.0/19"
    services_cidr_block          = "192.168.8.0/22"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
    }
    master_cidr_block = "10.1.10.0/28"
  }
}

variable "cluster_deletion_protection" {
  description = "Deletion protection for GKE clusters."
  type        = bool
  default     = true
}

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the cluster."
  type        = string
  default     = "gke"
}

variable "cluster_release_channel" {
  description = "GKE Release Channel."
  type        = string
  default     = "REGULAR"
}

variable "cluster_roles" {
  description = "GKE Service Account roles."
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ]
}

variable "cws_custom_images" {
  description = "Map of custom Cloud Workstation images."
  type = map(object({
    build = optional(object({
      skaffold_path   = optional(string)
      timeout_seconds = optional(number)
      machine_type    = optional(string)
      env             = optional(map(string), {})
      included_files  = optional(list(string), [])
    }))
    workstation_config = optional(object({
      scheduler_region = optional(string)
      ci_schedule      = optional(string)
      paused           = optional(bool, false)
    }))
    git_repo = optional(object({
      url    = string
      branch = string
    }))
    github = optional(object({
      owner          = string
      repo           = string
      branch_pattern = string
    }))
    ssm = optional(object({
      instance_id = string
      repo_name   = string
      branch      = string
    }))
  }))
  default = {}
}

variable "default_agentic_instructions" {
  description = "The default system instructions passed to the agent to define its behavior."
  type        = string
  default     = "You are an automated platform review agent. Adopt the requested personas to audit the workspace codebase changes."
}

variable "default_agentic_location" {
  description = "The default Agent Platform endpoint location for the agentic review models."
  type        = string
  default     = "global"
}

variable "default_agentic_model" {
  description = "The default Gemini model used for the agentic review (e.g., 'gemini-3.5-flash')."
  type        = string
  default     = "gemini-3.5-flash"
}

variable "default_agentic_personas" {
  description = "The default list of persona profiles to run during the automated review (e.g., 'swe', 'security')."
  type        = list(string)
  default     = ["swe", "security"]
}

variable "default_agentic_prompt" {
  description = "The default prompt passed to each persona reviewer."
  type        = string
  default     = "Analyze the modified files in the workspace. Audit the code against your persona's mandates and guidelines, highlighting any issues or improvements needed."
}

variable "developers" {
  description = "List of developers, e.g. to create Cloud Workstations."
  type        = list(string)
  default     = []
}

variable "disable_public_ip_addresses_default" {
  description = "The default for disabling public IP addresses for Cloud Workstation instances."
  type        = bool
  default     = true
}

variable "docker_image_tag" {
  description = "Tag of the Docker container image."
  type        = string
  default     = "20.10.24"
}

variable "enable_nested_virtualization_default" {
  description = "The default for enabling nested virtualization for Cloud Workstation instances."
  type        = bool
  default     = false
}

variable "folder_dev_id" {
  description = "Folder-ID that references existing Development folder."
  type        = number
  default     = null
}

variable "folder_hub_id" {
  description = "Folder-ID that references existing Hub folder."
  type        = number
  default     = null
}

variable "folder_prod_id" {
  description = "Folder-ID that references existing Production folder."
  type        = number
  default     = null
}

variable "folder_test_id" {
  description = "Folder-ID that references existing Testing folder."
  type        = number
  default     = null
}

variable "folders_create" {
  description = "Create folders instead of using existing ones."
  type        = bool
  default     = false
}

variable "gcloud_image_tag" {
  description = "Tag of the GCloud container image."
  type        = string
  default     = "562.0.0"
}

variable "git_branch_trigger" {
  description = "Branch used for the Cloud Build trigger. Used by Secure Source Manager (SSM)."
  type        = string
  default     = "main"
}

variable "git_branch_trigger_regexp" {
  description = "Regular expression for the Cloud Build trigger. Not used by Secure Source Manager (SSM)."
  type        = string
  default     = "^main$"
}

variable "github_owner" {
  description = "Owner of the GitHub repository. Leave null to provision Secure Source Manager by default."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "Name of the GitHub repository. Leave null to provision Secure Source Manager by default."
  type        = string
  default     = null
}

variable "idle_timeout_seconds_default" {
  description = "The default idle timeout in seconds for Cloud Workstation instances."
  type        = number
  default     = 1800
}

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image."
  type        = string
  default     = ""
}

variable "machine_type_default" {
  description = "Machine type of Cloud Workstations instance."
  type        = string
  default     = "e2-standard-4"
}

variable "nat_name" {
  description = "Name of the CloudNAT instance."
  type        = string
  default     = "nat"
}

variable "org_id" {
  description = "Organization-ID that references existing organization."
  type        = number
}

variable "persistent_disk_fs_type_default" {
  description = "Filesystem type of the Cloud Workstations persistent disk."
  type        = string
  default     = "ext4"
}

variable "persistent_disk_reclaim_policy_default" {
  description = "Reclaim policy of the Cloud Workstations persistent disk."
  type        = string
  default     = "RETAIN"
}

variable "persistent_disk_type_default" {
  description = "Disk type of the Cloud Workstations persistent disk."
  type        = string
  default     = "pd-standard"
}

variable "pool_size_default" {
  description = "Cloud Workstations pool size (to speed up startup time)."
  type        = number
  default     = 1
}

variable "prod_canary_percentages" {
  description = "Traffic percentages for GKE Gateway Service Mesh canary deployments in prod (set null to disable canary)."
  type        = list(number)
  default     = [10, 25, 50]
}

variable "prod_canary_verify" {
  description = "Whether to run Cloud Deploy verification steps during prod GKE canary deployments."
  type        = bool
  default     = false
}

variable "project_dev_host" {
  description = "Project-ID for dev host project."
  type        = string
}

variable "project_dev_host_services" {
  description = "Service APIs to enable on dev host project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_dev_service" {
  description = "Project-ID for dev service project."
  type        = string
}

variable "project_dev_service_services" {
  description = "Service APIs to enable on dev service project."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
  ]
}

variable "project_dev_supplychain" {
  description = "Project-ID for dev supplychain project."
  type        = string
}

variable "project_dev_supplychain_services" {
  description = "Service APIs to enable on dev supplychain project."
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

variable "project_hub_host" {
  description = "Project-ID for hub host project."
  type        = string
}

variable "project_hub_host_services" {
  description = "Service APIs to enable on hub host project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "project_hub_supplychain" {
  description = "Project-ID for hub supplychain project."
  type        = string
}

variable "project_hub_supplychain_services" {
  description = "Service APIs to enable on hub supplychain project."
  type        = list(string)
  default = [
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerscanning.googleapis.com",
    "ondemandscanning.googleapis.com",
    "orgpolicy.googleapis.com",
    "secretmanager.googleapis.com",
    "securesourcemanager.googleapis.com",
    "workstations.googleapis.com",
  ]
}

variable "project_prod_host" {
  description = "Project-ID for prod host project."
  type        = string
}

variable "project_prod_host_services" {
  description = "Service APIs to enable on prod host project."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_prod_service" {
  description = "Project-ID for prod service project."
  type        = string
}

variable "project_prod_service_services" {
  description = "Service APIs to enable on prod service project."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
  ]
}

variable "project_prod_supplychain" {
  description = "Project-ID for prod supplychain project."
  type        = string
}

variable "project_prod_supplychain_services" {
  description = "Service APIs to enable on prod supplychain project."
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

variable "project_test_host" {
  description = "Project-ID for test host project."
  type        = string
}

variable "project_test_host_services" {
  description = "Service APIs to enable on test host project."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "project_test_service" {
  description = "Project-ID for test service project."
  type        = string
}

variable "project_test_service_services" {
  description = "Service APIs to enable on test service project."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
  ]
}

variable "project_test_supplychain" {
  description = "Project-ID for test supplychain project."
  type        = string
}

variable "project_test_supplychain_services" {
  description = "Service APIs to enable on test supplychain project."
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

variable "projects_create" {
  description = "Create projects instead of using existing ones."
  type        = bool
  default     = false
}

variable "region" {
  description = "Compute region used."
  type        = string
  default     = "us-central1"
}

variable "runtimes" {
  description = "List of supported runtime solutions for applications."
  type        = list(string)
  default     = ["agentruntime", "cloudrun", "gke", "workstations"]
}

variable "sa_cluster_name" {
  description = "Name of GKE Service Account(s)."
  type        = string
  default     = "sa-gke"
}

variable "secure_source_manager_always_create" {
  description = "If true, create Secure Source Manager resources even when GitHub is configured."
  type        = bool
  default     = false
}

variable "skaffold_image_tag" {
  description = "Tag of the Skaffold container image."
  type        = string
  default     = "v2.18.1"
}

variable "ssm_branch_rule" {
  description = "Branch protection rule configuration for Secure Source Manager."
  type = object({
    allow_stale_reviews    = optional(bool, false)
    branch_rule_id         = optional(string, "main-linear")
    create                 = optional(bool, false)
    include_pattern        = optional(string)
    require_linear_history = optional(bool, true)
    require_pull_request   = optional(bool, true)
  })
  default = {}
}

variable "ssm_region" {
  description = "Region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations."
  type        = string
  default     = "europe-west4"
}

variable "vpc-dev-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC."
  type        = string
  default     = "10.77.0.0/22"
}

variable "vpc-dev-build_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.62.0.0/16"
}

variable "vpc-dev_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.65.0.0/16"
}

variable "vpc-hub_primary_cidr" {
  description = "CIDR for the primary subnet in the hub VPC."
  type        = string
  default     = "10.8.0.0/22"
}

variable "vpc-hub_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.60.0.0/16"
}

variable "vpc-prod-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC."
  type        = string
  default     = "10.79.0.0/22"
}

variable "vpc-prod-build_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.66.0.0/16"
}

variable "vpc-prod_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.63.0.0/16"
}

variable "vpc-test-build_primary_cidr" {
  description = "CIDR for the primary subnet in the build VPC."
  type        = string
  default     = "10.78.0.0/22"
}

variable "vpc-test-build_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.67.0.0/16"
}

variable "vpc-test_psa_cidr" {
  description = "PSA CIDR range."
  type        = string
  default     = "10.64.0.0/16"
}

variable "vpc_create" {
  description = "Flag indicating whether the VPC should be created or not."
  type        = bool
  default     = true
}

variable "vpc_subnet_name" {
  description = "Name of the subnet hosting the cluster."
  type        = string
  default     = "primary"
}

variable "ws_pd_disk_size_gb" {
  description = "Disk size in GB of the Cloud Workstations mounted /home persistent disk."
  type        = number
  default     = 200
}

variable "zone" {
  description = "Compute zone used."
  type        = string
  default     = "us-central1-a"
}
# go/keep-sorted end
