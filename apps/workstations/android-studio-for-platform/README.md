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

# Android Studio for Platform (ASFP) Custom Image for Cloud Workstations

The [CICD-Foundation](https://github.com/GoogleCloudPlatform/cicd-foundation)
[Blueprint for Cloud Workstations](https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/infra/blueprints/workstations)
automates the deployment of
[Cloud Workstations](https://docs.cloud.google.com/workstations/docs/overview)
using this custom image example for **Android Studio for Platform (ASFP)**.
It is designed for AOSP (Android Open Source Project) developers who need a high-performance, pre-configured environment in the cloud.

The **ASFP Custom Image for Cloud Workstations** is a specialized image layer built on top of the [GNOME Workstation Blueprint](../gnome/README.md). It provides a complete AOSP development environment, including the specialized ASFP IDE and necessary build tooling.

## 🚀 Key Features

- **ASFP Optimized**: Pre-installed and configured Android Studio for Platform, the IDE designed specifically for AOSP development.
- **AOSP Ready**: Includes all essential build tools (bison, build-essential, flex, repo, etc.) required for platform-level development.
- **Cuttlefish Integration**: Full support for the Cuttlefish Android emulator, allowing for virtual device testing directly within the workstation.
- **High-Performance Storage**: Optional ABFS (Android Build File System) client integration for optimized build speeds.
- **AOSP Helper Scripts**: Built-in scripts for common tasks like `build_aosp.sh`, `start_vcar_cvd.sh`, and `stop_vcar_cvd.sh`.

## 🏗️ Architecture

This image uses a **multi-layered build strategy**:

1.  **Base Layer**: [GNOME Workstation](../gnome/Dockerfile) - Handles the core OS (Ubuntu 24.04), systemd, GNOME Shell 46, and remote access protocols.
2.  **ASFP Layer**: [Dockerfile](./Dockerfile) - Injects specialized hooks (`10_install_aosp_tooling.sh`, `20_patch_asfp_desktop.sh`), custom assets, and tools to layer on top of the foundation.

## 🛠️ Build Arguments

This image supports and propagates all base arguments, including:

| Argument              | Default  | Description                                                     |
| :-------------------- | :------- | :-------------------------------------------------------------- |
| `ASFP_VERSION`        | `canary` | The version of ASFP to install.                                 |
| `INSTALL_ABFS_CLIENT` | `false`  | Whether to install the ABFS (Android Build File System) client. |

## 📖 Documentation

- **[Design Document](./docs/design.md)**: Deep-dive into the layering, hook-based integration logic, and Cuttlefish setup.
- **[Technical Requirements](./docs/requirements.md)**: Functional and non-functional requirements for the ASfP layer.
- **[System Overview](../../../docs/system_overview.md)**: High-level map of the entire Cloud Workstations Custom Image blueprint stack.
- **[Software Bill of Materials](./docs/software_bill_of_materials.md)**: Details on the packages and versions included in this image.
- **[Base Blueprint Docs](../gnome/docs/design.md)**: Deep-dives into the underlying systemd orchestrations and networking handover logic.

## Getting Started

1.  **Clone the CICD-Foundation**:
    ```bash
    git clone https://github.com/GoogleCloudPlatform/cicd-foundation.git
    cd cicd-foundation/infra/blueprints/workstations
    ```
2.  **Configure**: Create a `terraform.tfvars` file such as:

    ```hcl
    project_id = "YOUR_GCP_PROJECT_ID"

    # ASFP Custom Image Build
    cws_custom_images = {
      "asfp" : {
        git_repo = {
          url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
          branch = "main"
        }
        build = {
          skaffold_path = "apps/workstations/android-studio-for-platform/"
          machine_type  = "E2_HIGHCPU_32"
          # Pass environment variables to Skaffold to configure the Preflight UI source and Base Image
          env = {
            CWS_BASE_IMAGE_TAG = "latest"
            GCP_REGION         = "us-central1"
            PREFLIGHT_WEB_REPO = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
            PREFLIGHT_WEB_DIR  = "apps/workstations/preflight-web"
          }
        }
      }
    }

    # Workstation Cluster
    cws_clusters = {
      "workstations" = {
        network    = "workstations"
        region     = "us-central1"
        subnetwork = "primary"
      }
    }

    # Workstation Configuration
    cws_configs = {
      "custom" = {
        cws_cluster = "workstations"

        # Reference the custom image defined above
        custom_image_names = ["asfp"]

        # Hardware Specs (AOSP builds require significant resources)
        machine_type                 = "n2-standard-96"
        enable_nested_virtualization = true
        persistent_disk_size_gb      = 1000
        persistent_disk_type         = "pd-ssd"

        # Boost Configs
        boost_configs = [
          {
            id           = "gpu"
            machine_type = "n1-standard-96"
            accelerators = [
              {
                type  = "nvidia-tesla-t4"
                count = 1
              }
            ]
          }
        ]
      }
    }
    ```

3.  **Deploy**:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

For more information have a look at the **[Infrastructure & Deployment Guide](../../../docs/deployment_guide.md)**.
