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

# src

## Overview

Source container directory for the `java-hello-world` application, housing the
`java-hello-world` Maven Spring Boot container module.

## Subdirectories & Boundaries

- `java-hello-world`:
  [`./java-hello-world/EGM.md`](./java-hello-world/EGM.md) - Maven Spring Boot
  web application module (`org.skaffold:hello-spring-boot`).

## Interface

- [`./java-hello-world/EGM.md`](./java-hello-world/EGM.md): Exposes `pom.xml`
  and the `hello` Spring Boot package (`GET /`, `NAME`).

## Invariants

- Follows the repository convention `/apps/${APP_NAME}/src/${CONTAINER_NAME}/`
  where `${CONTAINER_NAME}` matches `java-hello-world`.

## Side Effects

- Delegates Maven build and Spring Boot HTTP runtime behavior to
  [`./java-hello-world/EGM.md`](./java-hello-world/EGM.md).
