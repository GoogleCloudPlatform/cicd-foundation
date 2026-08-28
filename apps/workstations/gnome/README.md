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

# Google Cloud Workstations - GNOME Blueprint

This repository defines a highly customized, multi-service Docker image for Google Cloud Workstations (CWS), featuring a professional GNOME desktop environment and a cinematic "Preflight" loading experience.

## 🚀 Quick Start by Role

Select your role to find the most relevant documentation and workflows:

- **[Architecture & Patterns](docs/design.md)**: Systemd orchestration, hook system, and developer patterns.
- **[Technical Requirements](docs/requirements.md)**: Functional and non-functional requirements for the GNOME layer.
- **[Operators / SREs](../../../skills/persona-sre/references/troubleshooting.md)**: Monitoring, logging, and troubleshooting.
- **[Security & Compliance](../../../docs/style_guides/docker.md)**: Hardening, ephemeral credentials, and SBOM.
- **[Hackathon Participants](../../../docs/hackathon_guide.md)**: Rapid prototyping and blueprint extension.

## 🏗️ Architectural Modules

This blueprint is organized into self-contained modules to ensure high maintainability and clarity. The GNOME layer is the top of a 4-tier stack:

### 1. GNOME Desktop Layer (`apps/workstations/gnome/`)

The core graphical shell providing Mutter, Wayland, and professional workspace extensions.

### 2. Remote Desktop Layer (`apps/workstations/remote-desktop/`)

The foundational parent to GNOME, providing the Apache Guacamole gateway and Remote Desktop daemon integration.

### 3. Common OS Layer (`apps/workstations/common/`)

The underlying orchestration layer compiling developer tooling (Antigravity, ADK, Chezmoi) into the image via dynamic hooks.

### 4. Preflight Dashboard (`apps/workstations/preflight/`)

A cinematic loading interface injected at the Base layer that intercepts early traffic and provides technical telemetry.

- 👉 **[UX Standards](../preflight/docs/design.md#33-cinematic-ux-principles)**
- 👉 **[Language Priorities](../preflight/docs/requirements.md#42-internationalization-i18n)**
- 👉 **[Design Document](../preflight/docs/design.md)**

## 🛠️ Global Tooling

- **Antigravity CLI**: Context-aware AI assistance directly in your terminal.
- **Skaffold**: Automated container build and deployment.
- **Bats & Vitest**: Comprehensive Bash and TypeScript testing suites.

## 🚀 Getting Started

To deploy this blueprint using the [cicd-foundation](https://github.com/GoogleCloudPlatform/cicd-foundation), follow these steps:

1.  **Clone the CICD-Foundation**:
    ```bash
    git clone https://github.com/GoogleCloudPlatform/cicd-foundation.git
    cd cicd-foundation/infra/blueprints/workstations
    ```
2.  **Configure**: Create a `terraform.tfvars` file using this complete example:

    ```hcl
    project_id = "YOUR_GCP_PROJECT_ID"

    # GNOME Custom Image Build
    cws_custom_images = {
      "gnome" : {
        git_repo = {
          url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
          branch = "main"
        }
        build = {
          skaffold_path = "apps/workstations/gnome/"
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
      "standard" = {
        cws_cluster        = "workstations"
        custom_image_names = ["gnome"]
        machine_type       = "e2-standard-8"
      }
    }
    ```

3.  **Deploy**:
    ```bash
    terraform init
    terraform apply
    ```

---

👉 **[Full Documentation Index](docs/README.md)** | 👉 **[AI Agents Instructions](AGENTS.md)**
