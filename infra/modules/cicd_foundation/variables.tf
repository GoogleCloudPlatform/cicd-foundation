# Copyright 2024-2026 Google LLC
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

# go/keep-sorted start block=yes newline_separated=yes
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

variable "namespace" {
  type        = string
  description = "A prefix to be added to resource names to ensure uniqueness."
  default     = ""
}

variable "project_id" {
  type        = string
  description = "Project-ID that references existing project."
}
# go/keep-sorted end

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

variable "deploy_region" {
  type        = string
  description = "The region to use for Cloud Deploy resources."
  default     = "us-central1"
}

variable "kms_keyring_location" {
  type        = string
  description = "The location for the KMS keyring."
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
# go/keep-sorted end

# Applications & Stages

variable "apps" {
  type = map(object({
    build = optional(object({
      # The relative path to the directory containing skaffold.yaml within the repository.
      skaffold_path = optional(string)
      # The timeout for the build in seconds.
      timeout_seconds = optional(number)
      # The machine type to use for the build.
      machine_type = optional(string)
      env          = optional(map(string), {})
      })
    )
    runtime = optional(string, "cloudrun"),
    stages  = optional(map(map(string))),
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
  description = "Map of applications to be deployed."
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.apps : sum([v.github != null ? 1 : 0, v.ssm != null ? 1 : 0, v.git_repo != null ? 1 : 0]) <= 1
    ])
    error_message = "An application can specify at most one source: github, ssm, or git_repo."
  }
}

variable "apps_directory" {
  type        = string
  description = "The root directory for applications in the repository. This is used to construct the path to an application's source code if `skaffold_path` is not specified."
  default     = "apps"
}

variable "runtimes" {
  type        = list(string)
  description = "List of supported runtime solutions for applications."
  default     = ["cloudrun", "gke", "workstations"]
}

variable "stages" {
  type = map(object({
    cloud_run_region                      = optional(string)
    gke_cluster                           = optional(string)
    project_id                            = optional(string)
    peered_network                        = optional(string)
    require_approval                      = optional(bool, false)
    canary_percentages                    = optional(list(number))
    canary_verify                         = optional(bool, false)
    binary_authorization_evaluation_mode  = optional(string, "ALWAYS_ALLOW")
    binary_authorization_enforcement_mode = optional(string, "DRYRUN_AUDIT_LOG_ONLY")
  }))
  description = "Map of deployment stages (e.g., dev, test, prod). Keys are stage names, values configure stage-specific settings like cluster, network, and Binary Authorization."
  default = {
    "dev" : {},
    "test" : {},
    "prod" : {},
  }
  validation {
    condition = alltrue([
      for stage_key, stage_value in var.stages :
      ! contains(keys(stage_value), "canary_percentages") || contains(keys(stage_value), "gke_cluster")
    ])
    error_message = "The 'canary_percentages' can only be set when 'gke_cluster' is also provided for the stage."
  }
  validation {
    condition = alltrue([
      for stage_key, stage_value in var.stages :
      contains(keys(stage_value), "canary_percentages") == contains(keys(stage_value), "canary_verify")
    ])
    error_message = "If either 'canary_percentages' or 'canary_verify' is set, both must be provided."
  }
}

# Artifact Registry

# go/keep-sorted start block=yes newline_separated=yes
variable "artifact_registry_id" {
  type        = string
  description = "The ID of an existing Docker Artifact Registry to use. If null, a new one will be created."
  default     = null
}

variable "artifact_registry_name" {
  type        = string
  description = "The name of the Artifact Registry repository to create if artifact_registry_id is null."
  default     = "cicd-foundation"
}

variable "artifact_registry_readers" {
  type        = list(string)
  description = "List of service account emails in IAM email format to grant Artifact Registry reader role."
  default     = []
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

variable "secure_source_manager_ca_common_name" {
  type        = string
  description = "The common name for the root CA certificate."
  default     = "SSM Root CA"
}

variable "secure_source_manager_ca_key_algorithm" {
  type        = string
  description = "The key algorithm to use for the root CA."
  default     = "RSA_PKCS1_4096_SHA256"
}

variable "secure_source_manager_ca_lifetime_seconds" {
  type        = string
  description = "The lifetime of the root CA certificate in seconds."
  default     = "315360000s" # 10 years
}

variable "secure_source_manager_ca_organization" {
  type        = string
  description = "The organization name for the root CA certificate."
  default     = "Terraform"
}

variable "secure_source_manager_ca_pool" {
  type        = string
  description = "The CA pool to use for issuing instance certificates for a private Secure Source Manager instance, in the format projects/{project}/locations/{location}/caPools/{ca_pool}. If null and secure_source_manager_create_ca_pool is true, a new pool will be created."
  default     = null
}

variable "secure_source_manager_create_ca_pool" {
  type        = bool
  description = "If true, and secure_source_manager_ca_pool is not set, creates a new CA Pool and Root CA for use with a private Secure Source Manager instance."
  default     = false
  validation {
    condition     = ! var.secure_source_manager_create_ca_pool || var.secure_source_manager_ca_pool == null
    error_message = "Cannot set secure_source_manager_create_ca_pool to true when secure_source_manager_ca_pool is provided."
  }
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
  description = "The name of the Secure Source Manager instance to create, if secure_source_manager_instance_id is null."
  default     = "cicd-foundation"
}

variable "secure_source_manager_repo_git_url_to_clone" {
  type        = string
  description = "The URL of a Git repository to clone into the new Secure Source Manager repository. If null, cloning is skipped."
  default     = null
}

variable "secure_source_manager_repo_name" {
  type        = string
  description = "The name of the Secure Source Manager repository."
  default     = "cicd-foundation"
}
# go/keep-sorted end

# Cloud Scheduler

variable "default_ci_schedule" {
  type        = string
  description = "The default cron schedule for continuous integration triggers in Cloud Scheduler if not specified in the application config."
  default     = "0 0 * * *"
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

variable "cloud_build_api_key_display_name" {
  type        = string
  description = "The display name of the API key for Cloud Build."
  default     = "API key for Cloud Build"
}

variable "cloud_build_api_key_name" {
  type        = string
  description = <<-EOT
    The name of the API key for Cloud Build.
    You can import an existing API key by specifying its name here
    and running `terraform import`.
  EOT
  default     = "cloudbuild"
}

variable "cloud_build_peered_network" {
  type        = string
  description = "If set, configures Cloud Build to use a private worker pool connected to the specified VPC network. The network must be provided in the format projects/{project}/global/networks/{network}."
  default     = null
}

variable "cloud_build_pool_disk_size_gb" {
  type        = number
  description = "The disk size in GB for Cloud Build worker pool workers."
  default     = 100
}

variable "cloud_build_pool_machine_type" {
  type        = string
  description = "The machine type for Cloud Build worker pool workers."
  default     = "e2-standard-2"
}

variable "cloud_build_pool_name" {
  type        = string
  description = "The base name for the Cloud Build worker pools. Stage name will be appended."
  default     = "worker-pool"
}

variable "cloud_build_service_account_name" {
  type        = string
  description = "The name of the Cloud Build service account to create."
  default     = "cloudbuild"
}

variable "docker_image_tag" {
  type        = string
  description = "The tag of the gcr.io/cloud-builders/docker image to use."
  default     = "20.10.24"
}

variable "gcloud_image_tag" {
  type        = string
  description = "The tag of the gcr.io/google.com/cloudsdktool/cloud-sdk image to use."
  default     = "562.0.0"
}

variable "skaffold_image_tag" {
  type        = string
  description = "The tag of the gcr.io/k8s-skaffold/skaffold image to use."
  default     = "v2.18.1"
}

variable "skaffold_output" {
  type        = string
  description = "The filename for the Skaffold artifacts JSON output."
  default     = "artifacts.json"
}

variable "skaffold_quiet" {
  type        = bool
  description = "Suppress Skaffold console output during builds."
  default     = false
}
# go/keep-sorted end

# Binary Authorization

# go/keep-sorted start block=yes newline_separated=yes
variable "binary_authorization_always_create" {
  type        = bool
  description = "If true, create Binary Authorization resources even if kritis_signer_image is not provided."
  default     = false
}

variable "kms_digest_alg" {
  type        = string
  description = "The digest algorithm to use for KMS signing."
  default     = "SHA512"
}

variable "kms_key_destroy_scheduled_duration_days" {
  type        = number
  description = "The number of days to schedule the KMS key for destruction."
  default     = 60
}

variable "kms_key_name" {
  type        = string
  description = "The name of the KMS key used for signing attestations."
  default     = "vulnz-attestor-key"
}

variable "kms_keyring_name" {
  type        = string
  description = "The name of the KMS key ring."
  default     = "vulnz-attestor-keyring"
}

variable "kms_signing_alg" {
  type        = string
  description = "The KMS signing algorithm to use for the vulnerability attestor key."
  default     = "RSA_SIGN_PKCS1_4096_SHA512"
}

variable "kritis_policy_default" {
  type        = string
  description = "The default YAML content of the Kritis vulnerability signing policy."
  default     = <<-EOT
apiVersion: kritis.grafeas.io/v1beta1
kind: VulnzSigningPolicy
metadata:
  name: cicd-foundation
spec:
  imageVulnerabilityRequirements:
    maximumFixableSeverity: MEDIUM
    maximumUnfixableSeverity: LOW
    allowlistCVEs:
#    - projects/goog-vulnz/notes/CVE-2023-39321
EOT
}

variable "kritis_policy_file" {
  type        = string
  description = "Path to a Kritis vulnerability signing policy YAML file. If null, the content from kritis_policy_default is used."
  default     = null
}

variable "kritis_signer_image" {
  type        = string
  description = "The container image reference for the Kritis signer. If empty, signing is disabled."
  default     = ""
}

variable "vulnz_attestor_name" {
  type        = string
  description = "The name of the Binary Authorization Attestor and the Container Analysis note."
  default     = "vulnz-attestor"
}
# go/keep-sorted end

# Cloud Deploy

# go/keep-sorted start block=yes newline_separated=yes
variable "canary_route_update_wait_time_seconds" {
  type        = number
  description = "The time (in seconds) to wait for network route updates during GKE canary deployments."
  default     = 60
}

variable "canary_verify" {
  type        = bool
  description = "Whether to enable verification steps for canary deployments in Cloud Deploy."
  default     = true
}

variable "service_account_cloud_deploy_name" {
  type        = string
  description = "The base name for the Cloud Deploy service accounts. Stage name will be appended."
  default     = "cloud-deploy"
}
# go/keep-sorted end

# Cloud Workstations

# go/keep-sorted start block=yes newline_separated=yes
variable "boot_disk_size_gb_default" {
  type        = number
  description = "The default boot disk size in GB for Cloud Workstation instances."
  default     = 100
}

variable "cws_image_build_runner_role_create" {
  type        = bool
  description = "Whether to create the custom IAM role for the Cloud Workstation Image Build Runner. If false, the role is expected to exist."
  default     = true
}

variable "cws_image_build_runner_role_id" {
  type        = string
  description = "The role_id for the custom IAM role for the Cloud Workstation Image Build Runner."
  default     = "cwsBuildRunner"
}

variable "cws_image_build_runner_role_title" {
  type        = string
  description = "The title for the custom IAM role for the Cloud Workstation Image Build Runner."
  default     = "Cloud Workstation Image Build Runner"
}

variable "cws_scopes" {
  type        = list(string)
  description = "The scope of the Cloud Workstations Service Account."
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "cws_service_account_name" {
  type        = string
  description = "Name of the Cloud Workstations Service Account."
  default     = "workstations"
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

variable "persistent_disk_fs_type_default" {
  type        = string
  description = "The default filesystem type for Cloud Workstation persistent disks."
  default     = "ext4"
}

variable "persistent_disk_reclaim_policy_default" {
  type        = string
  description = "The default reclaim policy for Cloud Workstation persistent disks."
  default     = "RETAIN"
}

variable "persistent_disk_type_default" {
  type        = string
  description = "The default disk type for Cloud Workstation persistent disks."
  default     = "pd-balanced"
}

variable "pool_size_default" {
  type        = number
  description = "The default pool size for Cloud Workstation instances."
  default     = 0
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
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.cws_custom_images : sum([v.github != null ? 1 : 0, v.ssm != null ? 1 : 0, v.git_repo != null ? 1 : 0]) <= 1
    ])
    error_message = "A custom image can specify at most one source: github, ssm, or git_repo."
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
    boot_disk_size_gb = optional(number)
    creators          = optional(list(string))
    # In case custom images shall be used, the keys from the cws_custom_images map.
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
