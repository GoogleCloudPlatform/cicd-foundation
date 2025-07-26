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
