# Infrastructure Setup

## Objectives 🎯

For Day 1 the following resources need to be provisioned:
1. Cloud Workstation Cluster & Config  
   so that users can create their Cloud Workstation instances
1. Artifact Registry  
   centrally deployed to be used by environments
1. Cloud Build (CB) Private Worker pools per environment and
1. HA-VPN between VPCs  
   so that the (VPC-peered) GKE Control plane can be accessed from CB workers

## Approach

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

### Cloud Storage Bucket

This is for storing the Terraform state file.  
It is recommended to create / use a bucket in a (central) "seed" project that is used for infrastructure automation.  

👉 Change `YOUR_BUCKET` in `backend.tf.example` and rename to `backend.tf`.

#### References 🔗

- [Create a new bucket](https://cloud.google.com/storage/docs/creating-buckets#create_a_new_bucket)

## Provision through IaC

👉 First authenticate:

```sh
gcloud auth application-default login
```

👉 Then execute Terraform:

```sh
terraform init
terraform apply
```

## Clean-up

You can delete all terraform-managed resources with the following command:

```sh
terraform destroy
```
