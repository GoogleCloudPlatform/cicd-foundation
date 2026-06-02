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

# Terraform Style Guide

This guide defines the standards for Terraform code within this repository, specifically for the orchestration of Cloud Workstations infrastructure and CI/CD pipelines.

We follow the authoritative [Google Cloud Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform) and the [HashiCorp Style Guide](https://developer.hashicorp.com/terraform/language/syntax/style).

## 1. Project Structure and Naming

### File Conventions

- **`main.tf`**: The primary entry point. For small modules, this contains all resources.
- **`variables.tf`**: All input variable definitions.
- **`outputs.tf`**: All output definitions.
- **`versions.tf`**: `terraform {}` block with required providers and version constraints.
- **`locals.tf`**: Complex local expressions to keep `main.tf` readable.

### Naming Standards

- **Underscores**: Use `lower_snake_case` for all resource names, variable names, and output names.
- **Resource Names**: Do not repeat the provider prefix in the name.
  - _Bad_: `resource "google_project" "google_project_main" {}`
  - _Good_: `resource "google_project" "main" {}`
- **Descriptive Variables**: Variable names should be nouns that clearly describe the value.

## 2. Resource Layout and Attribute Order

### Block Order

Within a resource or module block, attributes and nested blocks should be organized as follows:

1.  **Meta-arguments**: `count`, `for_each`, `provider`, `lifecycle`, `depends_on` (always at the top).
2.  **Required Attributes**: Mandatory fields for the resource.
3.  **Optional Attributes**: Non-mandatory fields.
4.  **Blocks**: Nested configuration blocks (e.g., `labels {}`, `settings {}`).

### Newline Requirements

- **Separation**: Use a single newline to separate meta-arguments from attributes.
- **Grouping**: Use newlines to group related attributes or to separate attributes from nested blocks.
- **Block Separation**: Ensure exactly one blank line between top-level blocks (`resource`, `data`, `module`, `variable`).

### Sorting (The Google Standard)

- **Alphabetize**: Within each category (required, optional, blocks), attributes MUST be alphabetized.
- **Linter**: Use `go/keep-sorted` comments where appropriate to maintain this order automatically.

## 3. Coding Standards

### Formatting

- **`terraform fmt`**: Mandatory. All files must be formatted using the built-in `terraform fmt` tool.
- **Indentation**: Use 2 spaces for indentation.
- **Alignment**: Align `=` signs within blocks to improve readability.

### Documentation

- **Descriptions**: Every `variable` and `output` MUST include a `description` block explaining its purpose.
- **Comments**: Use `#` for single-line comments. Document the "Why" for complex logic or non-obvious configurations.

### Handling Secrets

- **NEVER** hardcode secrets, API keys, or service account keys in Terraform files.
- Use Secret Manager or sensitive variables injected via the CI/CD pipeline.

## 4. Orchestration: Variable Flow to Skaffold

Terraform acts as the primary orchestrator for build-time configuration. When defining a custom image in the `cws_custom_images` block, configuration is passed to the build pipeline via the `env` map.

- **Environment Variables**: Variables defined in the `env` map are injected as environment variables into the CI/CD build environment (e.g., Cloud Build).
- **Skaffold Bridge**: These variables are then consumed by Skaffold using the `{{.VARIABLE_NAME}}` template syntax within `skaffold.yaml` to set Docker `buildArgs`.
- **Standard Variables**: Always include `CWS_BASE_IMAGE_TAG`, `GCP_REGION`, `PREFLIGHT_WEB_REPO`, and `PREFLIGHT_WEB_DIR` in the `env` block to ensure consistent build behavior.

## 5. Example Module Layout

```hcl
module "cicd_foundation" {
  source  = "github.com/GoogleCloudPlatform/cicd-foundation//infra/blueprints/workstations?ref=main"

  project_id = var.project_id

  cws_clusters = {
    "workstations" = {
      network    = "workstations"
      region     = "us-central1"
      subnetwork = "primary"
    }
  }

  cws_configs = {
    "standard" = {
      cws_cluster        = "workstations"
      custom_image_names = ["gnome"]
      machine_type       = "e2-standard-8"
    }
  }

  cws_custom_images = {
    "gnome" = {
      git_repo = {
        branch = "main"
        url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
      }
      build = {
        skaffold_path = "apps/workstations/gnome/"
        env = {
          CWS_BASE_IMAGE_TAG = "latest"
          GCP_REGION         = "us-central1"
          PREFLIGHT_WEB_REPO = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
          PREFLIGHT_WEB_DIR  = "apps/workstations/preflight-web"
        }
      }
    }
  }
}
```
