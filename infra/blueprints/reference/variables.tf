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
        "dev"  = { "replicas" = "1" }
        "test" = { "replicas" = "3" }
        "prod" = { "replicas" = "3" }
      }
    }
    "java-hello-world" = {
      runtime = "cloudrun"
      stages = {
        "dev"  = { "replicas" = "1" }
        "test" = { "replicas" = "3" }
        "prod" = { "replicas" = "3" }
      }
    }
    "node-hello-world" = {
      runtime = "gke"
      stages = {
        "dev"  = { "replicas" = "1" }
        "test" = { "replicas" = "3" }
        "prod" = { "replicas" = "3" }
      }
    }
    "python-hello-world" = {
      runtime = "gke"
      stages = {
        "dev"  = { "replicas" = "1" }
        "test" = { "replicas" = "3" }
        "prod" = { "replicas" = "3" }
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
  description = "Name of the GKE cluster in each spoke service project."
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
  description = "List of developer identities (bare emails or IAM principal strings) granted workstation and observability permissions."
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

variable "environments" {
  description = "Map of spoke environments (e.g., dev, test, prod) provisioned around the Hub, ordered by `order` in Cloud Deploy delivery pipelines."
  type = map(object({
    order               = number
    folder_display_name = string
    folder_id           = optional(number)
    projects = object({
      host                 = string
      supplychain          = string
      service              = string
      host_services        = optional(list(string))
      supplychain_services = optional(list(string))
      service_services     = optional(list(string))
    })
    network = object({
      nodes_cidr_block              = string
      pods_cidr_block               = string
      services_cidr_block           = string
      proxy_only_subnet_cidr_block  = string
      master_cidr_block             = string
      master_authorized_cidr_blocks = optional(map(string), { internal = "10.0.0.0/8" })
      psa_cidr                      = string
      build_primary_cidr            = string
      build_psa_cidr                = string
    })
    grant_developer_cluster_access        = optional(bool, false)
    disable_public_endpoint               = optional(bool, true)
    gke_internal_ip                       = optional(bool, true)
    enable_binary_authorization           = optional(bool, true)
    require_approval                      = optional(bool, false)
    canary_percentages                    = optional(list(number))
    canary_verify                         = optional(bool, false)
    binary_authorization_evaluation_mode  = optional(string, "ALWAYS_ALLOW")
    binary_authorization_enforcement_mode = optional(string, "DRYRUN_AUDIT_LOG_ONLY")
  }))
  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one spoke environment must be defined in `environments`."
  }
}

variable "folder_hub_id" {
  description = "Folder-ID that references existing Hub folder when `folders_create = false`."
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

variable "spoke_host_services" {
  description = "Default service APIs enabled on spoke Shared VPC host projects (overridable per environment via `projects.host_services`)."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

variable "spoke_service_services" {
  description = "Default service APIs enabled on spoke runtime service projects (overridable per environment via `projects.service_services`)."
  type        = list(string)
  default = [
    "binaryauthorization.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
  ]
}

variable "spoke_supplychain_services" {
  description = "Default service APIs enabled on spoke supplychain projects (overridable per environment via `projects.supplychain_services`)."
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

variable "vpc_create" {
  description = "Flag indicating whether VPC networks should be created or reused."
  type        = bool
  default     = true
}

variable "vpc_hub_primary_cidr" {
  description = "CIDR for the primary subnet in the hub VPC."
  type        = string
  default     = "10.8.0.0/22"
}

variable "vpc_hub_psa_cidr" {
  description = "PSA CIDR range for the hub VPC."
  type        = string
  default     = "10.60.0.0/16"
}

variable "vpc_subnet_name" {
  description = "Name of the primary subnet in the hub and spoke VPCs."
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
