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

# Skaffold Style Guide

This guide defines the standards for `skaffold.yaml` configurations within this repository. Skaffold serves as the critical bridge between Terraform orchestration and the Docker build process.

## 1. Orchestration: The Variable Bridge

Skaffold's primary role in this repository is to map environment variables (passed by Terraform or the CI/CD pipeline) to Docker `buildArgs`.

### Variable Flow Pattern

1.  **Terraform**: Defines configuration in the `env` block of the `cws_custom_images` module.
2.  **Skaffold**: Receives these as environment variables and consumes them using Go template syntax.
3.  **Dockerfile**: Declares `ARG` instructions to receive the values.

### Build Arguments Definition

- **Template Syntax**: Always use the `{{.VARIABLE_NAME}}` syntax to reference environment variables.
- **Default Values**: Utilize the `default` template function to provide fallback values, ensuring builds remain stable even if a variable is missing.

## 2. Standard Example

Every `skaffold.yaml` should follow this structure and indentation:

```yaml
apiVersion: skaffold/v3
kind: Config
metadata:
  name: my-image-layer
build:
  artifacts:
    - image: my-image
      context: .
      docker:
        dockerfile: Dockerfile
        network: cloudbuild
        buildArgs:
          CWS_BASE_IMAGE_TAG: '{{.CWS_BASE_IMAGE_TAG | default "latest"}}'
          GCP_REGION: '{{.GCP_REGION | default "us-central1"}}'
          PREFLIGHT_WEB_REPO: '{{.PREFLIGHT_WEB_REPO | default ""}}'
          PREFLIGHT_WEB_DIR: '{{.PREFLIGHT_WEB_DIR | default ""}}'
```

## 3. Artifact Configuration

### Context and Dockerfile

- **Relative Paths**: Always use relative paths for `context` and `dockerfile` to ensure portability.
- **Clean Context**: Utilize `.dockerignore` files rigorously to keep the build context small and avoid leaking sensitive files.

### Image Dependencies

- **`requires` Block**: Use the `requires` block to define build-time dependencies between images (e.g., a child layer requiring the `gnome` foundation).
- **Aliases**: Use the `alias` field to provide a stable name for the dependent image that can be referenced in the `Dockerfile`'s `FROM` instruction.
- **Mandatory Alias**: Always use `BASE_IMAGE` as the alias when referencing a dependency to a base image layer. This ensures a consistent interface for `FROM` instructions across all Dockerfiles.

## 4. Metadata

- **Name**: Every `skaffold.yaml` MUST have a descriptive `metadata.name` that matches its directory or layer name.
