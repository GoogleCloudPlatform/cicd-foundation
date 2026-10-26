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

# java-hello-world

## Overview

Skaffold application package (`java-hello-world`) that builds the Java 17 Spring
Boot web service in `src/java-hello-world` using Google Cloud Buildpacks
(`GOOGLE_RUNTIME_VERSION=17`) and deploys environment-specific Kubernetes and
Knative manifests (`envs/base`, `envs/dev`, `envs/test`, `envs/prod`) via
Kustomize and `kubectl`.

## Subdirectories & Boundaries

- `src`: [`./src/EGM.md`](./src/EGM.md) - Source directory containing the
  `java-hello-world` Maven Spring Boot container module.

## Interface

- `skaffold.yaml`: Skaffold configuration (`java-hello-world`, `apiVersion:
skaffold/v4beta9`) building artifact `java-hello-world` (context
  `src/java-hello-world` via `buildpacks` with `GOOGLE_RUNTIME_VERSION=17`)
  and defining `dev`, `test`, and `prod` Kustomize profiles (`portForward`
  8080->8080 in `dev`).
- `envs/`: Kustomize base (`envs/base/deployment.yaml`, `gateway.yaml`,
  `knative.yaml.tmpl`, `kustomization.yaml`, `namespace.yaml`, `route.yaml`,
  `service.yaml`) and environment overlays (`envs/dev`, `envs/test`,
  `envs/prod`).
- [`./src/EGM.md`](./src/EGM.md): Spring Boot application implementation (`GET
/`, `NAME`).

## Invariants

- Before manifest rendering, Skaffold executes the pre-manifest host hook
  `/bin/sh -c "../../bin/generate.sh 2>/dev/null || true"`.
- Buildpacks environment enforces `GOOGLE_RUNTIME_VERSION=17`.
- Deployment stabilization deadline (`statusCheckDeadlineSeconds`) is `3600`
  seconds with `tolerateFailuresUntilDeadline: true`.

## Side Effects

- Pre-manifest hook invokes `../../bin/generate.sh` to render template
  manifests (`knative.yaml.tmpl`).
- Building and deploying via Skaffold builds the container image with
  Buildpacks and applies Kustomize manifests to the target Kubernetes cluster
  via `kubectl`.
