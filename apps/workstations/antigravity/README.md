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

# Antigravity Custom Image for Cloud Workstations

The [CICD-Foundation](https://github.com/GoogleCloudPlatform/cicd-foundation)
[Blueprint for Cloud Workstations](https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/infra/blueprints/workstations)
automates the deployment of
[Cloud Workstations](https://docs.cloud.google.com/workstations/docs/overview)
using this custom image example for [Antigravity](https://antigravity.google/).
It is designed for a self-service model where developers can create their own
Cloud Workstation instances.

The **Antigravity Custom Image for Cloud Workstations** is a specialized image layer built on top of the [GNOME Workstation Blueprint](../gnome/README.md). It is designed to provide a highly productive, pre-configured desktop environment for Google Cloud Workstations, specifically tailored for hackathons, advanced development, and cloud-native engineering.

## 🚀 Key Features

- **Foundation-First**: Seamlessly integrates with the [cicd-foundation](https://github.com/GoogleCloudPlatform/cicd-foundation) workstations blueprint.
- **Headless Excellence**: Leverages the base blueprint's headless Wayland and RDP/Guacamole stack for low-latency browser-based access.
- **Dev-Ready**: Includes a customizable Agent Development Kit (ADK) and the Gemini CLI agent by default.

## 🏗️ Architecture

This image uses a **multi-layered build strategy**:

1.  **Base Layer**: [GNOME Workstation](../gnome/Dockerfile) - Handles the core OS (Ubuntu 24.04), systemd, GNOME Shell 46, and remote access protocols.
2.  **Antigravity Layer**: [Dockerfile](./Dockerfile) - Injects specialized build-time hooks (e.g., `10_install_antigravity.sh`), custom assets, and tools to layer on top of the foundation.

## 🛠️ Build Arguments

This image supports and propagates all base arguments, including:

| Argument                               | Default | Description                                      |
| :------------------------------------- | :------ | :----------------------------------------------- |
| `INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON` | `true`  | Installs the Python-based Agent Development Kit. |
| `INSTALL_GEMINI_CLI`                   | `true`  | Installs the Gemini CLI agent.                   |

## 📖 Documentation

- **[Design Document](./docs/design.md)**: Deep-dive into the thin-layer architecture, hook-based integration logic, and declarative packaging.
- **[System Overview](../../../docs/system_overview.md)**: High-level map of the entire Cloud Workstations Custom Image blueprint stack.
- **[Hackathon Guide](../../../docs/playbooks/hackathon_guide.md)**: A complete walkthrough for organizers deploying this environment at scale within customer organizations.
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

    # Antigravity Custom Image Build
    cws_custom_images = {
      "antigravity" : {
        git_repo = {
          url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
          branch = "main"
        }
        build = {
          skaffold_path = "apps/workstations/antigravity/"
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

        # Self-service: Grant permissions to a group or specific users to create their own instances
        #creators = ["group:developers@example.com"]

        # Reference the custom image defined above
        custom_image_names = ["antigravity"]

        # Best user experience: Keep >0 instance(s) ready in the pool for instant startup
        pool_size = 1

        # Hardware Specs
        machine_type                 = "e2-standard-8"
        enable_nested_virtualization = false
        persistent_disk_size_gb      = 500
        persistent_disk_type         = "pd-balanced"
      }
    }
    ```

3.  **Deploy**:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

For more information have a look at the **[Infrastructure & Deployment Guide](../docs/deployment_guide.md)**.
