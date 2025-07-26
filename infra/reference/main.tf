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

module "org" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/organization?ref=v34.0.0"
  organization_id = "organizations/${var.org_id}"
}

module "folder_hub" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.0.0"
  name          = "Hub"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_hub_id
}

module "folder_prod" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.0.0"
  name          = "Production"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_prod_id
}

module "folder_test" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.0.0"
  name          = "Testing"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_test_id
}

module "folder_dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder?ref=v34.0.0"
  name          = "Development"
  parent        = module.org.organization_id
  folder_create = var.folders_create
  id            = var.folder_dev_id
}

module "project_hub_host" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_hub_host
  parent         = "folders/${module.folder_hub.id}"
  project_create = var.projects_create
  services       = var.project_hub_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_hub_supplychain" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_hub_supplychain
  parent         = "folders/${module.folder_hub.id}"
  project_create = var.projects_create
  services       = var.project_hub_supplychain_services
  # org_policies = {
  #   "iam.disableCrossProjectServiceAccountUsage" = {
  #     rules = [{ enforce = false }]
  #   }
  # }
  shared_vpc_service_config = {
    host_project = module.project_hub_host.project_id
    service_identity_iam = {
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
    "roles/containeranalysis.notes.attacher" = [module.sa-cb.iam_email],
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
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_prod_host
  parent         = "folders/${module.folder_prod.id}"
  project_create = var.projects_create
  services       = var.project_prod_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_prod_supplychain" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_prod_supplychain
  parent         = "folders/${module.folder_prod.id}"
  project_create = var.projects_create
  services       = var.project_prod_supplychain_services
  # org_policies = {
  #   "iam.disableCrossProjectServiceAccountUsage" = {
  #     rules = [{ enforce = false }]
  #   }
  # }
  shared_vpc_service_config = {
    host_project = module.project_prod_host.project_id
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      "serviceAccount:${module.project_hub_supplychain.service_accounts.robots["clouddeploy"]}"
    ]
  }
}

module "project_prod_service" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_prod_service
  parent         = "folders/${module.folder_prod.id}"
  project_create = var.projects_create
  services       = var.project_prod_service_services
  shared_vpc_service_config = {
    host_project = module.project_prod_host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ],
    }
  }
  iam = {
    "roles/binaryauthorization.attestorsVerifier" = [
      "serviceAccount:${module.project_prod_service.service_accounts.robots["binaryauthorization"]}"
    ],
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
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_test_host
  parent         = "folders/${module.folder_test.id}"
  project_create = var.projects_create
  services       = var.project_test_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_test_supplychain" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_test_supplychain
  parent         = "folders/${module.folder_test.id}"
  project_create = var.projects_create
  services       = var.project_test_supplychain_services
  # org_policies = {
  #   "iam.disableCrossProjectServiceAccountUsage" = {
  #     rules = [{ enforce = false }]
  #   }
  # }
  shared_vpc_service_config = {
    host_project = module.project_test_host.project_id
  }
  iam = {
    "roles/cloudbuild.workerPoolUser" = [
      "serviceAccount:${module.project_hub_supplychain.service_accounts.robots["clouddeploy"]}"
    ]
  }
}

module "project_test_service" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_test_service
  parent         = "folders/${module.folder_test.id}"
  project_create = var.projects_create
  services       = var.project_test_service_services
  shared_vpc_service_config = {
    host_project = module.project_test_host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ],
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ],
    }
  }
  iam = {
    "roles/binaryauthorization.attestorsVerifier" = [
      "serviceAccount:${module.project_test_service.service_accounts.robots["binaryauthorization"]}"
    ],
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
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_dev_host
  parent         = "folders/${module.folder_dev.id}"
  project_create = var.projects_create
  services       = var.project_dev_host_services
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project_dev_supplychain" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_dev_supplychain
  parent         = "folders/${module.folder_dev.id}"
  project_create = var.projects_create
  services       = var.project_dev_supplychain_services
  # cf. https://cloud.google.com/deploy/docs/cloud-deploy-service-account#using_service_accounts_from_a_different_project
  # ad 1)
  # org_policies = {
  #   "iam.disableCrossProjectServiceAccountUsage" = {
  #     rules = [{ enforce = false }]
  #   }
  # }
  shared_vpc_service_config = {
    host_project = module.project_dev_host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
  iam = {
    # cf. https://cloud.google.com/deploy/docs/execution-environment#changing_from_the_default_pool_to_a_private_pool
    "roles/cloudbuild.workerPoolUser" = [
      "serviceAccount:${module.project_hub_supplychain.service_accounts.robots["clouddeploy"]}"
    ]
  }
}

module "project_dev_service" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v32.0.0"
  name           = var.project_dev_service
  parent         = "folders/${module.folder_dev.id}"
  project_create = var.projects_create
  services       = var.project_dev_service_services
  shared_vpc_service_config = {
    host_project = module.project_dev_host.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices",
        "container-engine",
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
  iam = {
    "roles/binaryauthorization.attestorsVerifier" = [
      "serviceAccount:${module.project_dev_service.service_accounts.robots["binaryauthorization"]}"
    ],
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
