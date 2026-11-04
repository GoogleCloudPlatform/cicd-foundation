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

module "org" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/organization?ref=v45.0.0"
  organization_id = "organizations/${var.org_id}"
}

module "folder_hub" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0"
  name          = "Hub"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_hub_id != null ? "folders/${var.folder_hub_id}" : null
}

module "folder_prod" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0"
  name          = "Production"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_prod_id != null ? "folders/${var.folder_prod_id}" : null
}

module "folder_test" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0"
  name          = "Testing"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_test_id != null ? "folders/${var.folder_test_id}" : null
}

module "folder_dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0"
  name          = "Development"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_dev_id != null ? "folders/${var.folder_dev_id}" : null
}

module "project_hub_host" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_hub_host
  parent        = module.folder_hub.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_hub_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_hub_supplychain" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_hub_supplychain
  parent        = module.folder_hub.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_hub_supplychain_services
  shared_vpc_service_config = {
    host_project = module.project_hub_host.project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
        "workstations",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ],
    }
  }
  iam = {
    "roles/binaryauthorization.policyViewer" = var.developers,
    "roles/cloudbuild.builds.viewer"         = var.developers,
    "roles/clouddeploy.approver"             = var.developers,
    "roles/clouddeploy.viewer"               = var.developers,
    "roles/workstations.workstationCreator"  = var.developers,
    "roles/workstations.operationViewer"     = var.developers,
  }
}

resource "google_project_iam_member" "hub_container_developer" {
  count   = length(var.developers)
  project = module.project_hub_supplychain.id
  role    = "roles/browser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "hub_container_occurrences_viewer" {
  count   = length(var.developers)
  project = module.project_hub_supplychain.id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "hub_logging_viewer" {
  count   = length(var.developers)
  project = module.project_hub_supplychain.id
  role    = "roles/logging.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "hub_monitoring_viewer" {
  count   = length(var.developers)
  project = module.project_hub_supplychain.id
  role    = "roles/monitoring.viewer"
  member  = var.developers[count.index]
}

module "project_prod_host" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_prod_host
  parent        = module.folder_prod.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_prod_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_prod_supplychain" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_prod_supplychain
  parent        = module.folder_prod.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_prod_supplychain_services
  shared_vpc_service_config = {
    host_project = module.project_prod_host.project_id
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      module.project_hub_supplychain.service_agents["clouddeploy"].iam_email
    ]
  }
}

module "project_prod_service" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_prod_service
  parent        = module.folder_prod.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_prod_service_services
  shared_vpc_service_config = {
    host_project = module.project_prod_host.project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ],
    }
  }
}

resource "google_project_iam_member" "prod_browser" {
  count   = length(var.developers)
  project = module.project_prod_service.id
  role    = "roles/browser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "prod_logging_viewer" {
  count   = length(var.developers)
  project = module.project_prod_service.id
  role    = "roles/logging.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "prod_monitoring_viewer" {
  count   = length(var.developers)
  project = module.project_prod_service.id
  role    = "roles/monitoring.viewer"
  member  = var.developers[count.index]
}

module "project_test_host" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_test_host
  parent        = module.folder_test.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_test_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_test_supplychain" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_test_supplychain
  parent        = module.folder_test.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_test_supplychain_services
  shared_vpc_service_config = {
    host_project = module.project_test_host.project_id
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      module.project_hub_supplychain.service_agents["clouddeploy"].iam_email
    ]
  }
}

module "project_test_service" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_test_service
  parent        = module.folder_test.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_test_service_services
  shared_vpc_service_config = {
    host_project = module.project_test_host.project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ],
    }
  }
}

resource "google_project_iam_member" "test_browser" {
  count   = length(var.developers)
  project = module.project_test_service.id
  role    = "roles/browser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "test_logging_viewer" {
  count   = length(var.developers)
  project = module.project_test_service.id
  role    = "roles/logging.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "test_monitoring_viewer" {
  count   = length(var.developers)
  project = module.project_test_service.id
  role    = "roles/monitoring.viewer"
  member  = var.developers[count.index]
}

module "project_dev_host" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_dev_host
  parent        = module.folder_dev.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_dev_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_dev_supplychain" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_dev_supplychain
  parent        = module.folder_dev.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_dev_supplychain_services
  shared_vpc_service_config = {
    host_project = module.project_dev_host.project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      module.project_hub_supplychain.service_agents["clouddeploy"].iam_email
    ]
  }
}

module "project_dev_service" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = var.project_dev_service
  parent        = module.folder_dev.id
  project_reuse = var.projects_create ? null : {}
  services      = var.project_dev_service_services
  shared_vpc_service_config = {
    host_project = module.project_dev_host.project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
}

resource "google_project_iam_member" "dev_browser" {
  count   = length(var.developers)
  project = module.project_dev_service.id
  role    = "roles/browser"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "dev_container_developer" {
  count   = length(var.developers)
  project = module.project_dev_service.id
  role    = "roles/container.developer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "dev_logging_viewer" {
  count   = length(var.developers)
  project = module.project_dev_service.id
  role    = "roles/logging.viewer"
  member  = var.developers[count.index]
}

resource "google_project_iam_member" "dev_monitoring_viewer" {
  count   = length(var.developers)
  project = module.project_dev_service.id
  role    = "roles/monitoring.viewer"
  member  = var.developers[count.index]
}
