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

# Infrastructure Blueprints (`blueprints`)

## Overview

Groups deployable Terraform root blueprints under `infra/blueprints` that
compose foundational CI/CD and Cloud Workstations modules with project
networking, firewall rules, and IAM policies for end-to-end environment
provisioning.

## Subdirectories & Boundaries

- [Workstations Blueprint](./workstations/EGM.md): Deploys and manages Google
  Cloud Workstations, VPC/Cloud NAT/firewall networking, project IAM bindings,
  Android branch/target configuration matrices, and custom container image
  CI/CD pipelines via `cicd_foundation`.
