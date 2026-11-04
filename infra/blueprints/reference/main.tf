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

locals {
  developer_iam_members = [
    for principal in var.developers :
    length(regexall("^(user|group|serviceAccount|domain|principal|principalSet):", principal)) > 0 ? principal : "user:${principal}"
  ]
}

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

module "folder_spoke" {
  for_each      = var.environments
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v45.0.0"
  name          = each.value.folder_display_name
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = each.value.folder_id != null ? "folders/${each.value.folder_id}" : null
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
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine",
      ]
    }
  }
  iam = {
    "roles/binaryauthorization.policyViewer"     = local.developer_iam_members
    "roles/browser"                              = local.developer_iam_members
    "roles/cloudbuild.builds.viewer"             = local.developer_iam_members
    "roles/clouddeploy.approver"                 = local.developer_iam_members
    "roles/clouddeploy.viewer"                   = local.developer_iam_members
    "roles/containeranalysis.occurrences.viewer" = local.developer_iam_members
    "roles/logging.viewer"                       = local.developer_iam_members
    "roles/monitoring.viewer"                    = local.developer_iam_members
    "roles/workstations.operationViewer"         = local.developer_iam_members
    "roles/workstations.workstationCreator"      = local.developer_iam_members
  }
}

module "project_spoke_host" {
  for_each      = var.environments
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = each.value.projects.host
  parent        = module.folder_spoke[each.key].id
  project_reuse = var.projects_create ? null : {}
  services      = coalesce(each.value.projects.host_services, var.spoke_host_services)
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_spoke_supplychain" {
  for_each      = var.environments
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = each.value.projects.supplychain
  parent        = module.folder_spoke[each.key].id
  project_reuse = var.projects_create ? null : {}
  services      = coalesce(each.value.projects.supplychain_services, var.spoke_supplychain_services)
  shared_vpc_service_config = {
    host_project = module.project_spoke_host[each.key].project_id
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      module.project_hub_supplychain.service_agents["clouddeploy"].iam_email,
    ]
  }
}

module "project_spoke_service" {
  for_each      = var.environments
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v45.0.0"
  name          = each.value.projects.service
  parent        = module.folder_spoke[each.key].id
  project_reuse = var.projects_create ? null : {}
  services      = coalesce(each.value.projects.service_services, var.spoke_service_services)
  shared_vpc_service_config = {
    host_project = module.project_spoke_host[each.key].project_id
    service_agent_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine",
      ]
    }
  }
  iam = merge(
    {
      "roles/browser"           = local.developer_iam_members
      "roles/logging.viewer"    = local.developer_iam_members
      "roles/monitoring.viewer" = local.developer_iam_members
    },
    each.value.grant_developer_cluster_access ? {
      "roles/container.developer" = local.developer_iam_members
    } : {},
  )
}
