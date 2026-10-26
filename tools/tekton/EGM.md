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

# Tekton Installation (`tools/tekton`)

## Overview

Provides an installation script (`installation.sh`) to provision Tekton
Pipelines, Tekton Triggers, Tekton Triggers Interceptors, the `git-clone`
catalog task, and local Tekton task and pipeline manifests onto a Kubernetes
cluster.

## Interface

- `installation.sh`: Executes `kubectl apply` against upstream Tekton release
  manifests and local `task/*.yaml` and `pipeline/*.yaml` definitions.

## Invariants

- Expects `kubectl` to be installed and configured with an active Kubernetes
  cluster context.
- Expects sibling directories `task/` and `pipeline/` relative to
  `installation.sh` containing `*.yaml` manifest files.

## Side Effects

- Fetches and applies remote Kubernetes manifests from
  `https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml`,
  `https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml`,
  `https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml`,
  and
  `https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml`
  to the active Kubernetes cluster.
- Applies all local Kubernetes manifest files matching
  `"$SCRIPT_DIR"/task/*.yaml` and `"$SCRIPT_DIR"/pipeline/*.yaml` to the active
  Kubernetes cluster.
