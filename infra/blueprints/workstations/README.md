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

# Cloud Workstations Terraform Blueprint

This blueprint contains Terraform configuration for deploying and managing
[Cloud Workstations](https://cloud.google.com/workstations/docs/overview) on
Google Cloud. It provides a standardized way to create workstation clusters,
configurations, and instances, including support for custom container images.

By leveraging this blueprint, you can automate the provisioning of secure and
consistent development environments tailored to your team's needs.

## Features

- Deploys Cloud Workstations Cluster, Config, and Workstation resources.
- Supports launching workstations from Google-provided
  [preconfigured base images](https://cloud.google.com/workstations/docs/preconfigured-base-images)
  or your own
  [custom container images](https://cloud.google.com/workstations/docs/customize-container-images).
- Configurable machine types, disk types/sizes, regions, and network settings.
- Option to set IAM policies for workstations.

### Resources Provisioned by this Blueprint

This blueprint provisions the following key Cloud Workstations resources:

- **Workstation Cluster**: Provides the management layer and VPC connection
  for workstation configurations within a specific region.
- **Workstation Config**: Defines the template for workstations hosted in the
  cluster. This includes settings like:
  - Machine type, disk type, and size.
  - Idle timeout and running timeout.
  - The container image to use (either a preconfigured Google image or a
    custom image).
  - User or group assignments for IAM permissions.
- **Workstation Instances**: Individual workstations instance based on the
  config, which can be started and used by an assigned developer.

## Custom Image Build Process

This blueprint can be configured to use custom container images for
workstations. These images must be stored in an Artifact Registry repository,
which is assumed to be provisioned by the `cicd_foundation` module.

If custom images are defined via the `cws_custom_images` variable, the module
will also provision the necessary CI/CD components to build and maintain them
using either GitHub or Secure Source Manager (SSM) as source:

- **Secure Source Manager**: If `github_owner` is not provided, a Secure
  Source Manager instance and repository are provisioned. If the variable
  `secure_source_manager_repo_git_url_to_clone` is set, a one-time Cloud
  Build trigger clones the specified Git repository and pushes its content to
  the SSM repository.
- **Cloud Build Trigger**: For each custom image, a trigger is created that
  builds the container image from source (GitHub or SSM) containing a
  `skaffold.yaml` and pushes it to Artifact Registry upon changes to the
  source. If SSM is used, webhooks are automatically configured to trigger
  builds on push events; the initial clone and push described above will
  trigger the first build.
- **Cloud Scheduler**: For each custom image, a scheduled job is created that
  periodically triggers Cloud Build to rebuild the image. This is useful for
  incorporating security patches from base images or updating dependencies,
  ensuring the workstation image remains up-to-date.

## Usage

To deploy the resources defined in this blueprint:

1.  **Customize Variables**: Create a `.tfvars` file, e.g., by copying and
    adapting `terraform.tfvars.example` to match your environment settings and
    preferences.
2.  **Initialize Terraform**: Run `terraform init`.
3.  **Plan and Apply**: Run `terraform plan` to review the changes and
    `terraform apply` to provision the resources.

### Using Custom Images

This blueprint supports launching Workstations from Google maintained
Preconfigured base images or custom images built from your source code.
There are two ways to configure this:

**1. Automated Build and Configuration**

If you want this blueprint to automatically build your custom images from a
source repository _and_ create a corresponding Workstation Config for each
image, you should:

- Define your images in the `cws_custom_images` map variable, providing
  details such as the source repository and Dockerfile location.
- List the keys of the images you wish to build and deploy in the
  `custom_image_names` list attribute of your Cloud Workstation Config.

For each image key listed in `cws_custom_images`, this blueprint will provision
a Cloud Build trigger and a Cloud Scheduler job that uses the custom image built
by the trigger. The Workstation service accounts will be granted permissions
to pull these images from Artifact Registry.

**2. Manual Image Configuration**

If you want to create a Workstation Config that uses a pre-existing image (e.g.,
a Google-provided image like `base-editor`, or a custom image that is already
present in Artifact Registry and managed by a different process), you can define
the workstation configuration manually within your Terraform variables and
specify the image URI directly via the `image` attribute in its definition,
instead of using the `cws_custom_images` map.

## Inputs and Outputs

For details on configurable inputs and blueprint outputs, please see
`variables.tf` and `outputs.tf`.
