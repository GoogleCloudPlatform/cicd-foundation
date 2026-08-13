<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Reference Architecture

This code reflects a PSO opinionated-view with the following characteristics:

- Enterprise readiness
  - hub & spoke network architecture
- Resource Management
  - multi-environments (DEV, TEST, PROD)
- Security best practices
  - dedicated services accounts
- Infrastructure Automation
  - [Terraform](https://www.terraform.io/) is used for Infrastructure-as-Code (IaC).

For the runtime we make use of a GKE Autopilot cluster per environment.

## Prerequisites

### GCP Organization

The IaC assumes a GCP Organization and a resource management with folders and projects in different environments, i.e.,

- development (DEV)
- testing (TEST)
- production (PROD)

### Local variable values

👉 Create a `terraform.tfvars` file and set the following variables:

- `org_id`
- `folders_create = true`
- `projects_create = true`

👉 Assign the Organization ID to `org_id`.

You may want to override some default values from `variables.tf` (such as the default `region` and `zone`) or (eventually) set values such as:

- `folder_hub_id`
- `folder_dev_id`

#### References 🔗

- [Getting your organization resource ID](https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id)
