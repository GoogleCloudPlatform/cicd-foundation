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

variable "ssm_region" {
  description = "region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations"
  type        = string
  default     = "europe-west4"
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

variable "kritis_signer_image" {
  description = "Image ref to the kritis signer image"
  type        = string
}

variable "registry_id" {
  description = "String used to name Artifact Registry."
  type        = string
  default     = "registry"
}

# cf. https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
variable "cluster_release_channel" {
  description = "GKE Release Channel"
  type        = string
  default     = "REGULAR"
}

variable "cluster_deletion_protection" {
  description = "deletion protection for GKE clusters"
  type        = bool
  default     = false
}

variable "cluster_min_version" {
  description = "Minimum version of the control nodes, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "name of the cluster"
  type        = string
  default     = "gke"
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

variable "skaffold_image_tag" {
  description = "Tag of the Skaffold container image"
  type        = string
  default     = "v2.13.1"
}

variable "docker_image_tag" {
  description = "Tag of the Docker container image"
  type        = string
  default     = "20.10.24"
}

variable "gcloud_image_tag" {
  description = "Tag of the GCloud container image"
  type        = string
  default     = "490.0.0"
}

variable "developers" {
  description = "Map of developer(s) with their Google Identity used as the key and a map with their GitHub account and (forked) repo to use for the CI/CD OR an empty map in case they use Secure Source Manager"
  type = map(object({
    github_user = optional(string, "")
    github_repo = optional(string, "cicd-foundation")
  }))
}

variable "runtimes" {
  description = "List of runtime solutions."
  type        = list(string)
  default     = ["gke", "cloudrun", "workstation"]
}

variable "stages" {
  description = "List of deployment stages."
  type        = list(string)
  default     = ["dev", "test", "prod"]
}

variable "build_timeout_default" {
  description = "the default timeout in seconds for the Cloud Build build step"
  type        = number
  default     = 7200
}

variable "build_machine_type_default" {
  description = "the default machine type to use for Cloud Build build, cf. https://cloud.google.com/build/docs/api/reference/rest/v1/projects.builds#machinetype"
  type        = string
  default     = "UNSPECIFIED"
}

variable "apps" {
  description = "Map of applications as found within the apps/ folder, their build configuration, runtime, deployment stages and parameters."
  type = map(object({
    build = optional(object({
      timeout      = number
      machine_type = string
      })
    )
    runtime = optional(string, "cloudrun")
    stages  = optional(map(map(string)))
  }))
  default = {
    "go-hello-world" : {
      runtime = "gke",
      stages = {
        "dev" : {
          "replicas" : 1
        },
        "test" : {
          "replicas" : 3
        },
        "prod" : {
          "replicas" : 3
        },
      }
    },
    "java-hello-world" : {
      runtime = "cloudrun",
      stages = {
        "dev" : {
          "replicas" : 1
        },
        "test" : {
          "replicas" : 3
        },
        "prod" : {
          "replicas" : 3
        },
      }
    },
    "node-hello-world" : {
      runtime = "gke",
      stages = {
        "dev" : {
          "replicas" : 1
        },
        "test" : {
          "replicas" : 3
        },
        "prod" : {
          "replicas" : 3
        },
      }
    },
    "python-hello-world" : {
      runtime = "gke",
      stages = {
        "dev" : {
          "replicas" : 1
        },
        "test" : {
          "replicas" : 3
        },
        "prod" : {
          "replicas" : 3
        },
      }
    },
  }
}
