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

# Infrastructure & Deployment Guide

While it is possible to build custom images manually, deploying via the [CICD-Foundation](https://github.com/GoogleCloudPlatform/cicd-foundation) blueprint offers significant benefits through comprehensive infrastructure-as-code automation.

## Why use the CICD-Foundation?

- **Nightly Automated Builds**: Automatically provisions a [Cloud Scheduler](https://cloud.google.com/scheduler) job that triggers the Cloud Build pipeline nightly. This ensures your workstation images receive the latest upstream OS security patches and toolchain versions.
- **End-to-End Orchestration**: A single `terraform apply` provisions the dedicated VPC, subnets, Artifact Registry, Cloud Build pipelines, and the complete Cloud Workstations cluster and configuration.
- **High Level of Customization**: Complete control over the deployment, such as configuring the workstation cluster to deploy into an existing subnet of a Shared VPC.
- **Security & Compliance**: Implements Google Cloud's security best practices for IAM roles, network constraints, and service accounts.

## Execute the Deployment

Run these commands from the root of the `cicd-foundation` repository to provision the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

## Following the Deployment

The infrastructure provisioning and container build are triggered as part of the `terraform apply` process. You can follow the progress and verify the resources:

1.  **Observe the Build**: Monitor the image build process in the [Cloud Build Console](https://console.cloud.google.com/cloud-build/builds).
2.  **Verify the Image**: Once the build completes, the container image will be visible in the [Artifact Registry Console](https://console.cloud.google.com/artifacts).
3.  **Check Workstation Resources**: The cluster and its configurations can be viewed in the [Cloud Workstations Console](https://console.cloud.google.com/workstations).
4.  **Launch a Workstation**: Create and start a new workstation instance from the newly created configuration.

## Useful `gcloud` Commands

You can use the `gcloud` CLI to list and verify your resources:

```bash
# List Cloud Build runs
gcloud builds list

# List Artifact Registry images
gcloud artifacts docker images list $WS_REGION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/$REPOSITORY/$IMAGE_NAME

# List Cloud Workstation clusters
gcloud workstations clusters list --region=$WS_REGION

# List Cloud Workstation configurations
gcloud workstations configs list --cluster=$WS_CLUSTER --region=$WS_REGION
```

## Connecting via SSH

For developers who prefer connecting to their workstation via a secure SSH tunnel (e.g., for local IDE integration), we recommend using the [`ws.sh`](https://github.com/GoogleCloudPlatform/cicd-foundation/blob/main/bin/ws.sh) script from the CICD-Foundation repository.

```bash
# Download the script
curl -O https://raw.githubusercontent.com/GoogleCloudPlatform/cicd-foundation/main/bin/ws.sh
chmod +x ws.sh

export WS_REGION="YOUR_REGION"
export WS_CLUSTER="YOUR_CLUSTER"
export WS_CONFIG="YOUR_CONFIG"
./ws.sh
```
